#!/bin/sh
set -xe
if [ ! -f DeepSpeech.py ]; then
    echo "Please make sure you run this from DeepSpeech's top level directory."
    exit 1
fi;

# Force only one visible device because we have a single-sample dataset
# and when trying to run on multiple devices (like GPUs), this will break
export CUDA_VISIBLE_DEVICES=0

python -u DeepSpeech.py --noshow_progressbar \
  --alphabet_config_path ../learning/data/alphabet.ru \
  --scorer_path ../export/kenlm.scorer \
  --train_files ../learning/data/ru-train.csv \
  --test_files ../learning/data/ru-train.csv \
  --learning_rate 0.00095 \
  --train_batch_size 1 \
  --test_batch_size 1 \
  --n_hidden 100 \
  --epochs 500 \
  --checkpoint_dir ../learning/checkpoint \
  --export_dir ../export \
  --data_aug_features_additive 1 \
  --data_aug_features_multiplicative 1 \
  --augmentation_speed_up_std 1 \
  "$@"
