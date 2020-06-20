# Run it from directory with wav files
echo "wav_filename,wav_filesize,transcript" > noise.csv
for i in "$1"/*.wav
 do
   echo "$i,," >> noise.csv
done
