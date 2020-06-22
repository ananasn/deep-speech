## Требования:
* Python 3.7
* venv

## Подготовка:

1. Небходимо установить Git Large Storage. Расширение для обычной утилиты git,
 чтобы работать с большими файлами.
 ```
sudo apt install git-lfs
```
2. Подключить lfs к аккаунту git.
 ```
 git lfs install
```
3. Клонируем библиотеку DeepSpeech в рабочий репозиторий
```
git clone https://github.com/mozilla/DeepSpeech
```
4. Устанавливаем для сборки
```
sudo apt-get install python3-dev
```
5. Устанавливаем указанную в документации версию pip
 (https://deepspeech.readthedocs.io/en/v0.7.3/TRAINING.html#training-a-model),
 на данный момент это 20.0.2
```
cd ./DeepSpeech
pip3 install --upgrade pip==20.0.2 wheel==0.34.2 setuptools==46.1.3
```
6. Устанавливаем скачанный пакет и его зависимости в режиме разработчика
```
pip3 install --upgrade --force-reinstall -e .
```
7. На всякий случай устанавливаем библиотеки sox, потому что в документации написано,
 что они могут понадобиться
 ```
sudo apt-get install sox libsox-fmt-mp3
```

## Модель

Для руского языка нет модели языка и ее надо сделать до начала обучения. Можно на ограниченное количество фраз. 
Для этого нам понадобятся скрипты из директории
 `
learning/scripts/*
`
и специальные утилиты kenlm.

### Модель языка
#### Ставим  kenlm
1. Клонируем kenlm
```
git clone https://github.com/kpu/kenlm.git
```
2. Устанавливаем зависимости
```
sudo apt install libbz2-dev libeigen3-dev liblzma-dev libboost-all-dev
```

3. Ставим утилиты как написано в
 ./kenlm/README.md
````
cd ./kenlm
mkdir -p build
cd build
cmake ..
make -j 4
````
4. Создаем файл словаря. Для этого помещаем туда все транскрипции из аудиофайлов.
 Пример лежит в `./learning/data/vocabulary.txt`

5. Создаем scorer
```
python3  ./learning/scripts/generate_lm.py --input_txt learning/data/vocabulary.txt  --output_dir ./export --top_k 500000 --kenlm_bins  kenlm/build/bin/  --arpa_order 5 --max_arpa_memory "85%" --arpa_prune "0|0|1" --binary_a_bits 255 --binary_q_bits 8 --binary_type trie --discount_fallback
python3  ./learning/scripts/generate_package.py --alphabet learning/data/alphabet.ru --lm export/lm.binary --vocab export/vocab-500000.txt --package export/kenlm.scorer --default_alpha 0.931289039105002 --default_beta 1.1834137581510284
```

### Модель для распознавания
> **_NOTE:_** Есть уж готовый голосовой датасет на русском языке. Размер файла большой, 2 ГБ.
>https://voice.mozilla.org/en/datasets
#### Готовим датасет
1.Запись mp3
```
arecord test.mp3
```
2. Конвертируем в wav  (16bit, mono, yadda-yadda)
```
ffmpeg -i test.mp3 -acodec pcm_s16le -ar 16000 test.wav

или

for file in *.mp3; do ffmpeg -i "$file" -acodec pcm_s16le -ar 16000 "$file".wav; done

```
3. Для увеличения датасета будем использовать voice-corpus-tool. Устанавливаем:
```
git clone https://github.com/mozilla/voice-corpus-tool
cd ./voice-corpus-tool
pip3 install -r requirements.txt
```
4. Скачиваем архив с шумами https://jmvalin.ca/demo/rnnoise/ (15 ГБ)
или берем уже сконвертированные мной из ./learning/data/wav/noise

5. Конертруем raw в wav. 

Для этого скрипт `./learning/scripts/./convert.sh` 
помещаем в директорию с raw файлами. 
Внутри скрипта можно поменять маску, чтобы конвертить определенные файлы.
На выходе внутри директори появится директория noise с wav файлами.
````
./convert.sh
````
 6. Создаем csv для датасета шумов
 ```
cd ./learning/scripts
./generate_csv.sh ../data/wav/noise
mv noise.csv ../data/wav
```

7. Генерируем зашумленные файлы из одного ru-train.csv. 
В ru-train.csv должно быть записей столько же скольк в noise.csv.
Папки processed и файла processed.сsv не должно существовать. 

 ```
 ./voice.py add ../learning/data/ru-train.csv augment ../learning/data/wav/noise.csv write ../learning/data/wav/processed
или с усилением шума
 ./voice.py add ../learning/data/ru-train.csv augment ../learning/data/wav/noise.csv -gain 2 write ../learning/data/wav/processed

```
9. Создаем csv-файл датасета следующего формата или используем получнный на предыдущем шаге
```csv
wav_filename,wav_filesize,transcript
ru.wav,0,бедняга ребят на его месте должен был быть я
```
wav_filename,wav_filesize,transcript -- заголовок

ru.wav -- путь до файла

"бедняга ребят на его месте должен был быть я" -- транскрипция

10. Датасет лучше разделить на три части
* train -- 70 %
* dev -- 20 %
* test -- 10 %

Для каждой части делается отдельный csv  и в  run.sh казывается путь соответствующими флагами:
* --train_files
* --dev_files
* --test_files
#### Обучаем модель
1. Очищаем папку checkpont, если хотим обучать сначала
 
2. Запускаем, можно поменять параметры внутри скрипта
```
cd ../DeepSpeech/
./../learning/run.sh 
```
3. Конвертируем модель в .pbmm
```
python ./util/taskcluster.py --source tensorflow --artifact convert_graphdef_memmapped_format --branch r1.15 --target .
sudo chmod +x convert_graphdef_memmapped_format 
./convert_graphdef_memmapped_format --in_graph=../export/output_graph.pb --out_graph=../export/output_graph.pbmm
```

## Проверка модели:
1. Скачиваем примеры (в нашем случае уже лежит в корне)
```
 https://github.com/mozilla/DeepSpeech-examples.git
```
2. Берем оттуда пример vad_transcriber 
3. Ставим недостающие модули 
```
pip3 install webrtcvad deepspeech pyqt5
```
4. Запускаем
```
 python3 audioTranscript_gui.py 
 ```
5. Не забывам указать папку, где лежит модель и scorer. В нашем случае `./export`.
