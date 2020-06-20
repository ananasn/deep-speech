# Run it from directory with raw files
mkdir -p noise
n=0
m=50
for i in *.raw; do
    n=$(($n + 1))
    if [ "$n" -gt "$m" ];
    then
        echo "Current max number $n, you can change to other in script"
        break  # Завершение работы цикла.
    fi
    o=noise/${i#rawfiles/}
    sox --type raw --rate 8k --bits 16 --channels 1 --encoding signed "$i" "${o%.raw}.wav"
done
