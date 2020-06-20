# Run it from directory with raw files
mkdir -p noise
for i in *.raw; do
    o=noise/${i#rawfiles/}
    sox --type raw --rate 8k --bits 16 --channels 1 --encoding signed "$i" "${o%.raw}.wav"
done
