#!/usr/bin/env bash

# check the enviroment info
nvidia-smi
PYTHON="/root/miniconda3/bin/python"
# PYTHON="/root/miniconda3/envs/pytorch1.0/bin/python"

export PYTHONPATH="/msravcshare/yuyua/code/segmentation/openseg.pytorch":$PYTHONPATH

cd ../../

DATA_DIR="/msravcshare/dataset/pascal_voc"
SAVE_DIR="/msravcshare/dataset/seg_result/pascal_voc/"
BACKBONE="deepbase_resnet101_dilated8"
CONFIGS="configs/pascal_voc/${BACKBONE}.json"
CONFIGS_TEST="configs/pascal_voc/${BACKBONE}_test.json"

MODEL_NAME="sparse_ocnet_longshort"
LOSS_TYPE="fs_auxohemce_loss"
CHECKPOINTS_NAME="${MODEL_NAME}_${BACKBONE}_ohem_5w_"$2
LOG_FILE="./log/pascal_voc/${CHECKPOINTS_NAME}.log"

PRETRAINED_MODEL="./pretrained_model/resnet101-imagenet.pth"
MAX_ITERS=60000


if [ "$1"x == "train"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} \
                       --drop_last y \
                       --nbb_mult 10 \
                       --phase train --gathered n --loss_balance y --log_to_file n \
                       --backbone ${BACKBONE} --model_name ${MODEL_NAME} --gpu 0 1 2 3 \
                       --data_dir ${DATA_DIR} --loss_type ${LOSS_TYPE} --max_iters ${MAX_ITERS} \
                       --pretrained ${PRETRAINED_MODEL} \
                       --checkpoints_name ${CHECKPOINTS_NAME} \
                       > ${LOG_FILE} 2>&1


elif [ "$1"x == "resume"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} \
                       --drop_last y \
                       --nbb_mult 10 \
                       --phase train --gathered n --loss_balance y --log_to_file n \
                       --backbone ${BACKBONE} --model_name ${MODEL_NAME} --max_iters ${MAX_ITERS} \
                       --data_dir ${DATA_DIR} --loss_type ${LOSS_TYPE} --gpu 0 1 2 3 \
                       --resume_continue y --resume ./checkpoints/pascal_voc/${CHECKPOINTS_NAME}_latest.pth \
                       --checkpoints_name ${CHECKPOINTS_NAME} --pretrained ${PRETRAINED_MODEL} \
                       >> ${LOG_FILE} 2>&1


elif [ "$1"x == "debug"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} --drop_last y \
                       --phase debug --gpu 0 --log_to_file n  > ${LOG_FILE} 2>&1


elif [ "$1"x == "val"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} \
                       --data_dir ${DATA_DIR} \
                       --backbone ${BACKBONE} \
                       --model_name ${MODEL_NAME} \
                       --checkpoints_name ${CHECKPOINTS_NAME} \
                       --phase test \
                       --gpu 0 1 2 3 \
                       --resume ./checkpoints/pascal_voc/${CHECKPOINTS_NAME}_latest.pth \
                       --test_dir ${DATA_DIR}/val/image \
                       --log_to_file n \
                       --out_dir ${SAVE_DIR}${CHECKPOINTS_NAME}_val_ms

  cd lib/metrics
  ${PYTHON} -u ade20k_evaluator.py --configs ../../${CONFIGS} \
                                   --pred_dir ${SAVE_DIR}${CHECKPOINTS_NAME}_val_ms/label \
                                   --gt_dir ${DATA_DIR}/val/label  


elif [ "$1"x == "test"x ]; then
  ${PYTHON} -u main.py --configs ${CONFIGS} \
                       --data_dir ${DATA_DIR} \
                       --backbone ${BACKBONE} \
                       --model_name ${MODEL_NAME} \
                       --checkpoints_name ${CHECKPOINTS_NAME} \
                       --phase test \
                       --gpu 0 1 2 3 \
                       --resume ./checkpoints/pascal_voc/${CHECKPOINTS_NAME}_latest.pth \
                       --test_dir ${DATA_DIR}/test \
                       --log_to_file n \
                       --out_dir ${SAVE_DIR}${CHECKPOINTS_NAME}_test_ms

else
  echo "$1"x" is invalid..."
fi