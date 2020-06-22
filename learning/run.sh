#!/bin/sh
set -xe
if [ ! -f DeepSpeech.py ]; then
  echo "Please make sure you run this from DeepSpeech's top level directory."
  exit 1
fi

# Force only one visible device because we have a single-sample dataset
# and when trying to run on multiple devices (like GPUs), this will break
#  --data_aug_features_additive 0.6 \
#  --data_aug_features_multiplicative 0.6 \
##  --augmentation_speed_up_std 0.6 \
#  --dev_batch_size 2 \
#    --dev_files ../learning/data/wav/ru-dev.csv \



export CUDA_VISIBLE_DEVICES=0

python -u DeepSpeech.py --noshow_progressbar \
  --alphabet_config_path ../learning/data/alphabet.ru \
  --scorer_path ../export/kenlm.scorer \
  --train_files ../learning/data/wav/processed.csv \
  --test_files ../learning/data/wav/ru-test.csv \
  --learning_rate 0.0001 \
  --train_batch_size 2 \
  --test_batch_size 2 \
  --n_hidden 150 \
  --epochs 150 \
  --early_stop True \
  --dropout_rate 0.22 \
  --checkpoint_dir ../learning/checkpoint \
  --export_dir ../export \
  "$@"
