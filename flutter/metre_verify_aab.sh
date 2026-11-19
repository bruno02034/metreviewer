#!/usr/bin/env bash
# Metre: confere o .aab final antes de ir para a Google Play. Falha (exit 1) se algo não estiver certo.
# Uso: metre_verify_aab.sh <arquivo.aab> <SHA-256 esperado do certificado> [versionCode mínimo]
# Precisa de java/jarsigner/keytool no PATH; baixa o bundletool oficial do Google se faltar.
set -uo pipefail
AAB="$1"; EXPECTED="$2"; MIN_VC="${3:-1}"
PKG=com.metre.viewer
BT_VER=1.17.2
FAIL=0
ok()  { echo "  OK     $*"; }
bad() { echo "  FALHOU $*"; FAIL=1; }

BT="${BUNDLETOOL_JAR:-$(dirname "$0")/bundletool-all-$BT_VER.jar}"
if [ ! -f "$BT" ]; then
  curl -fsSL -o "$BT" "https://github.com/google/bundletool/releases/download/$BT_VER/bundletool-all-$BT_VER.jar" || { echo "sem bundletool"; exit 1; }
fi
bt() { java -jar "$BT" "$@"; }

echo "== $AAB"
# 1. estrutura (ferramenta oficial)
if bt validate --bundle="$AAB" >/dev/null 2>&1; then ok "bundletool validate"; else bad "bundletool validate"; bt validate --bundle="$AAB" 2>&1 | tail -5; fi

# 2. assinatura: válida, um único certificado, o da Metre, sem depuração
if jarsigner -verify "$AAB" 2>&1 | grep -q "jar verified"; then ok "jarsigner -verify"; else bad "jarsigner -verify"; fi
CERTS=$(keytool -J-Duser.language=en -printcert -jarfile "$AAB" 2>&1)
N=$(echo "$CERTS" | grep -c "^Owner:")
SHA=$(echo "$CERTS" | grep "SHA256:" | head -1 | awk '{print $2}')
[ "$N" = "1" ] && ok "um único certificado" || bad "certificados: $N"
[ "$SHA" = "$EXPECTED" ] && ok "certificado da Metre ($SHA)" || bad "certificado inesperado: $SHA"
echo "$CERTS" | grep -q "CN=Android Debug" && bad "assinatura de depuração presente" || ok "sem assinatura de depuração"

# 3. manifesto
MAN=$(bt dump manifest --bundle="$AAB" 2>/dev/null)
attr() { echo "$MAN" | grep -o "$1=\"[^\"]*\"" | head -1 | cut -d'"' -f2; }
[ "$(attr package)" = "$PKG" ] && ok "pacote $PKG" || bad "pacote $(attr package)"
VC=$(attr 'android:versionCode'); VN=$(attr 'android:versionName')
[ "${VC:-0}" -ge "$MIN_VC" ] 2>/dev/null && ok "versionCode $VC (>= $MIN_VC), versionName $VN" || bad "versionCode $VC < $MIN_VC"
echo "$MAN" | grep -q 'android:debuggable="true"' && bad "app marcado como depurável" || ok "não depurável"
MIN=$(attr 'android:minSdkVersion'); TGT=$(attr 'android:targetSdkVersion')
[ "${MIN:-99}" -le 24 ] && ok "minSdk $MIN (Android 7 = API 24 incluso)" || bad "minSdk $MIN exclui o Android 7"
[ "${TGT:-0}" -ge 36 ] && ok "targetSdk $TGT (Play exige 36 desde 31/08/2026)" || bad "targetSdk $TGT < 36"
for p in RECORD_AUDIO FOREGROUND_SERVICE_MICROPHONE MANAGE_EXTERNAL_STORAGE; do
  echo "$MAN" | grep -q "android.permission.$p\"" && bad "permissão $p presente" || ok "sem $p"
done

# 4. bibliotecas nativas: 32 e 64 bits, e páginas de 16 KB no 64 bits
TMP=$(mktemp -d)
LIBS=$(unzip -Z1 "$AAB" | grep '^base/lib/.*\.so$')
for abi in armeabi-v7a arm64-v8a; do
  echo "$LIBS" | grep -q "base/lib/$abi/librustdesk.so" && ok "librustdesk.so em $abi" || bad "falta librustdesk.so em $abi"
done
# alinhamento dos segmentos LOAD (ELF64): precisa ser >= 16384 para aparelhos com páginas de 16 KB
u() { od -An -t"u$2" -j "$1" -N "$2" "$3" | tr -d ' \n'; }
for so in $(echo "$LIBS" | grep '/arm64-v8a/'); do
  unzip -p "$AAB" "$so" > "$TMP/x.so"
  phoff=$(u 32 8 "$TMP/x.so"); phsz=$(u 54 2 "$TMP/x.so"); phn=$(u 56 2 "$TMP/x.so")
  minal=0
  for ((i=0; i<phn; i++)); do
    o=$((phoff + i*phsz))
    [ "$(u $o 4 "$TMP/x.so")" = "1" ] || continue  # PT_LOAD
    al=$(u $((o+48)) 8 "$TMP/x.so")
    if [ $minal = 0 ] || [ "$al" -lt "$minal" ]; then minal=$al; fi
  done
  name=$(basename "$so")
  [ "$minal" -ge 16384 ] && ok "16 KB: $name (alinhamento $minal)" || bad "16 KB: $name alinhado em $minal"
done
rm -rf "$TMP"

echo
[ $FAIL = 0 ] && echo "PRONTO para enviar ao Play Console (itens verificáveis localmente)." || echo "NÃO enviar: corrigir os itens FALHOU."
exit $FAIL
