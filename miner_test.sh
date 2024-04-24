#!/bin/bash
set -e

# Define color variables
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
# Define box drawing characters
HORIZONTAL_LINE="─"
VERTICAL_LINE="│"
TOP_LEFT_CORNER="┌"
TOP_RIGHT_CORNER="┐"
BOTTOM_LEFT_CORNER="└"
BOTTOM_RIGHT_CORNER="┘"

#==========================Define Variables=============================================#
CONDA_ACTIVATE="source activate /opt/conda/envs/gpu-3-11"
#CONFIG_FILE="/miner-release/config.toml"

SD_MINER=""

#Model Descriptions
llm_1="openhermes-2.5-mistral-7b-gptq (8 Bit-12GB RAM  0.1X Reward 🦙 )"
llm_2="openhermes-2-pro-mistral-7b (16-Bit-24GB RAM  0.2X Reward 🦙,🦙 )"
llm_3="openhermes-mixtral-8x7b-gptq(4 Bit-48GB RAM 1X Reward  🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙 )"
llm_4="openhermes-2-yi-34b-gptq (8 Bit- 48GB RAM 1X Reward  🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙 )"
sdm_sdxl="Stable Diffusion Miner --exclude-sdxl"
sdm="Stable Diffusion Miner"
# Point weightage for Llama and Waifu models
Llama_ratio=70
SD_ratio=30

# Fetch the total VRAM available and number of GPUs
total_vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | awk '{sum += $1} END {print sum}')
num_gpus=$(nvidia-smi --list-gpus | wc -l)
gpu_model=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)

# Calculate VRAM per GPU
vram_per_gpu=$((total_vram / num_gpus))

#==========================Functions=============================================# 

detect_gpus() {
num_gpus=$(nvidia-smi --list-gpus | wc -l)
total_vram=0
vram_info=""

for i in $(seq 0 $((num_gpus - 1))); do
    vram=$(nvidia-smi --id=$i --query-gpu=memory.total --format=csv,noheader,nounits)
    total_vram=$((total_vram + vram))
    vram_info="${vram_info}GPU $i: $vram MiB"
    if [ $i -lt $((num_gpus - 1)) ]; then
        vram_info="${vram_info}, "
    fi
done
}

update_sd_miner_command() {
    #SD_MINER="$(basename $(find /miner-release -type f -name 'sd-miner*.py' -print -quit))"
    SD_MINER="$(basename $(find / -type f -name 'sd-miner*.py' -path "*/miner-release/*" -print -quit))"
   

    if [ "$user_choice" = "n" ] || [ "$user_choice" = "N" ]; then
        if [ "$miner_choice" = "1" ]; then
            echo "Selected LLM Miner & SD-Miner (Exclude SDL)"
            sd_miner_command="yes | python3 $(eval echo "$SD_MINER") --log-level DEBUG --exclude-sdxl"
        elif [ "$miner_choice" = "2" ] || [ "$miner_choice" = "4" ]; then
            echo "Selected LLM Miner & SD-Miner (Include SDL)"
            sd_miner_command="yes | python3 $(eval echo "$SD_MINER") --log-level DEBUG"
        fi
    fi

    if [ "$user_choice" = "y" ] || [ "$user_choice" = "Y" ]; then
        if [ "$recommended_mining_option" = "1" ]; then
            echo "Selected LLM Miner & SD-Miner (Exclude SDL)"
            rec_sd_miner_cmd="yes | python3 $(eval echo "$SD_MINER") --log-level DEBUG --exclude-sdxl"
        elif [ "$recommended_mining_option" = "2" ] || [ "$recommended_mining_option" = "4" ]; then
            echo "Selected LLM Miner & SD-Miner (Include SDL)"
            rec_sd_miner_cmd="yes | python3 $(eval echo "$SD_MINER") --log-level DEBUG"
        fi
    fi
}

#Function to print a table
print_table() {
    local gpu_model="$1"
    local num_gpus="$2"
    local vram_info="$3"
    
    print_horizontal_line
    printf "${BLUE}%s %-50s %s %-20s %s %-20s %s${NC}\n" "$VERTICAL_LINE" "GPU Model" "$VERTICAL_LINE" "Number of GPUs" "$VERTICAL_LINE" "Total VRAM" "$VERTICAL_LINE"
    print_horizontal_line
    printf "${BLUE}%s %-50s %s %-20s %s %-20s %s${NC}\n" "$VERTICAL_LINE" "$gpu_model" "$VERTICAL_LINE" "$num_gpus" "$VERTICAL_LINE" "$vram_info" "$VERTICAL_LINE"
    print_horizontal_line
}

print_multiplier_table() {
    local llm_model="$1"
    local sd_model="$2"
    local llama_multiplier=""
    local waifu_multiplier=""
    
    # Determine the llama multiplier based on the llm_model
    case "$llm_model" in
        "openhermes-2.5-mistral-7b-gptq")
            llama_multiplier="0.1X Reward 🦙"
            ;;
        "openhermes-2-pro-mistral-7b")
            llama_multiplier="0.2X Reward 🦙,🦙"
            ;;
        "openhermes-mixtral-8x7b-gptq")
            llama_multiplier="1X Reward 🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙"
            ;;
        "openhermes-2-yi-34b-gptq")
            llama_multiplier="1X Reward 🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙"
            ;;
        *)
            llama_multiplier="Unknown"
            ;;
    esac
    
    # Determine the waifu multiplier based on the recommended_mining_option
    if [ "$recommended_mining_option" = "1" ]; then
        waifu_multiplier="1X Reward 🧚‍♀️"
    elif [ "$recommended_mining_option" = "2" ] || [ "$recommended_mining_option" = "4" ]; then
        waifu_multiplier="2X Reward 🧚‍♀️,🧚‍♀️"
    fi
    
    local llm_model_length=$((${#llm_model} + 10))
    local sd_model_length=$((${#sd_model} + 5))
    local llama_multiplier_length=$((${#llama_multiplier} + 5))
    local waifu_multiplier_length=$((${#waifu_multiplier} + 10))
    
    print_horizontal_line_multiplier
    printf "${GREEN}%s %-${llm_model_length}s %s %-${sd_model_length}s %s %-${llama_multiplier_length}s %s %-${waifu_multiplier_length}s %s${NC}\n" "$VERTICAL_LINE" "LLM Model" "$VERTICAL_LINE" "Stable Diffusion Model" "$VERTICAL_LINE" "Llama Multiplier" "$VERTICAL_LINE" "Waifu Multiplier" "$VERTICAL_LINE"
    print_horizontal_line_multiplier
    printf "%s %-${llm_model_length}s %s %-${sd_model_length}s %s %-${llama_multiplier_length}s %s %-${waifu_multiplier_length}s %s\n" "$VERTICAL_LINE" "$llm_model" "$VERTICAL_LINE" "$sd_model" "$VERTICAL_LINE" "$llama_multiplier" "$VERTICAL_LINE" "$waifu_multiplier" "$VERTICAL_LINE"
    print_horizontal_line_multiplier
}

# Function to print a horizontal line for the main table
print_horizontal_line() {
    printf "%s%s%s%s%s%s%s\n" "$TOP_LEFT_CORNER" "${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}" "$TOP_LEFT_CORNER" "${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}" "$TOP_LEFT_CORNER" "${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}${HORIZONTAL_LINE}" "$TOP_RIGHT_CORNER"
}

# Function to print a horizontal line for the multiplier table
print_horizontal_line_multiplier() {
    local llm_model_length=$((${#llm_model} + 10))
    local sd_model_length=$((${#sd_model} + 5))
    local llama_multiplier_length=$((${#llama_multiplier} + 5))
    local waifu_multiplier_length=$((${#waifu_multiplier} + 10))
    
    printf "%s%s%s%s%s%s%s%s%s\n" "$TOP_LEFT_CORNER" "$(printf '%*s' "$llm_model_length" | tr ' ' '-')" "$TOP_LEFT_CORNER" "$(printf '%*s' "$sd_model_length" | tr ' ' '-')" "$TOP_LEFT_CORNER" "$(printf '%*s' "$llama_multiplier_length" | tr ' ' '-')" "$TOP_LEFT_CORNER" "$(printf '%*s' "$waifu_multiplier_length" | tr ' ' '-')" "$TOP_RIGHT_CORNER"
}

#Function to recommend models based on available VRAM
recommend_models() {
#echo "Based on your system's VRAM configuration, the recommended model combination is:"
#echo "LLM Model, SD Model, Llama Multiplier, Waifu Multiplier"
# Best combination tracking
best_score=0
best_combination=""

# Conditionally check for 'openhermes-2-yi-34b-gptq' if active
if [ "$openhermes_2_yi_34b_gptq_active" = "y" ]; then
    check_combination 38000 100 6000 10 "openhermes-2-yi-34b-gptq" "SD Miner Including SDXL"
    check_combination 38000 100 4000 5 "openhermes-2-yi-34b-gptq" "SD Miner Excluding SDXL"
    check_combination 38000 100 0 0 "openhermes-2-yi-34b-gptq" "None"
fi

# Check all other combinations of LLM and SD
check_combination 32000 100 6000 10 "openhermes-mixtral-8x7b-gptq" "SD Miner Including SDXL"
check_combination 32000 100 4000 5 "openhermes-mixtral-8x7b-gptq" "SD Miner Excluding SDXL"
check_combination 18000 20 6000 10 "openhermes-2-pro-mistral-7b" "SD Miner Including SDXL"
check_combination 18000 20 4000 5 "openhermes-2-pro-mistral-7b" "SD Miner Excluding SDXL"
check_combination 11000 10 6000 10 "openhermes-2.5-mistral-7b-gptq" "SD Miner Including SDXL"
check_combination 11000 10 4000 5 "openhermes-2.5-mistral-7b-gptq" "SD Miner Excluding SDXL"

# Check LLM only (excluding the conditional model)
check_combination 32000 100 0 0 "openhermes-mixtral-8x7b-gptq" "None"
check_combination 18000 20 0 0 "openhermes-2-pro-mistral-7b" "None"
check_combination 11000 10 0 0 "openhermes-2.5-mistral-7b-gptq" "None"

# Check SD only
check_combination 0 0 6000 10 "None" "SD Miner Including SDXL"
check_combination 0 0 4000 5 "None" "SD Miner Excluding SDXL"

#if [ -n "$best_combination" ]; then
#    echo "$best_combination"
 classify_recommendation
#else
#    echo "No model combination can be recommended based on the available VRAM per GPU."
#fi
}

#Helper function to check and compare combinations
check_combination() {
llm_vram=$1
llama_multiplier=$2
sd_vram=$3
waifu_multiplier=$4
llm_model=$5
sd_model=$6
score=$((llama_multiplier + waifu_multiplier))

if [ $((llm_vram + sd_vram)) -le $vram_per_gpu ]; then
    if [ $score -gt $best_score ]; then
        best_score=$score
        best_combination="$llm_model, $sd_model, $((llama_multiplier / 10))X, $((waifu_multiplier / 10))X"
        rec_llm_model="$llm_model"
        rec_sd_model="$sd_model"
        update_commands "$llm_model" "$sd_model"
    fi
fi
score=$((llama_multiplier + waifu_multiplier))

if [ $((llm_vram + sd_vram)) -le $vram_per_gpu ]; then
    if [ $score -gt $best_score ]; then
        best_score=$score
        best_combination="$llm_model, $sd_model, $((llama_multiplier / 10))X, $((waifu_multiplier / 10))X"
        rec_llm_model="$llm_model"
        rec_sd_model="$sd_model"
        update_commands "$llm_model" "$sd_model"
    fi
fi
}

# Function to update command variables based on model selection
update_commands() {
    llm_model=$1
    sd_model=$2

    case "$llm_model" in
        "openhermes-2.5-mistral-7b-gptq") rec_llm_miner_cmd="./llm-miner-starter.sh openhermes-2.5-mistral-7b-gptq" ;;
        "openhermes-2-pro-mistral-7b") rec_llm_miner_cmd="./llm-miner-starter.sh openhermes-2-pro-mistral-7b" ;;
        "openhermes-mixtral-8x7b-gptq") rec_llm_miner_cmd="./llm-miner-starter.sh openhermes-mixtral-8x7b-gptq" ;;
        "openhermes-2-yi-34b-gptq") rec_llm_miner_cmd="./llm-miner-starter.sh openhermes-2-yi-34b-gptq" ;;
        *) rec_llm_miner_cmd="" ;;
    esac

}

# Function to classify the recommendation into one of the four categories
classify_recommendation() {
    if [ "$rec_llm_model" != "None" ] && [ "$rec_sd_model" != "None" ]; then
        if echo "$rec_sd_model" | grep -q "Excluding SDXL"; then
            recommended_mining_option="1"  # LLM + SD (Exclude SDXL)
        else
            recommended_mining_option="2"  # LLM +SD (Include SDXL)
        fi
    elif [ "$rec_llm_model" != "None" ] && [ "$rec_sd_model" = "None" ]; then
        recommended_mining_option="3"  # LLM only
    elif [ "$rec_llm_model" = "None" ] && [ "$rec_sd_model" != "None" ]; then
        recommended_mining_option="4"  # SD Only
    fi
    
     recommended_llm_model=""
    if [ "$vram_per_gpu" -ge 38000 ] && [ "$openhermes_2_yi_34b_gptq_active" = "y" ];then
        recommended_llm_model="4"
    elif [ "$vram_per_gpu" -ge 32000 ] ; then
        recommended_llm_model="3"
    elif [ "$vram_per_gpu" -ge 18000 ]; then
        recommended_llm_model="2"
    else
        recommended_llm_model="1"
    fi
}

    generate_ascii_art() {
    local text="$1"
    local font="standard"
    local width=80
    
    case "$text" in
        #"Heurist")
            #figlet -f "$font" -w "$width" "Heurist"
        #    ;;
        "Symbol")
echo "⠀⠀⠀⠀⠀⠀⠀ ⠀⠀     ⠀⠀⣀⣤⣾⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣾⣿⣿⣿⣿⠀⠀⠀⠀⢰⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"⠀⠀⠀
echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⠀⠀⠀⢀⣠⣴⣾⣿⣿⣿⣿⣿⡿⢿⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣷⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⣀⣤⣶⣿⣿⣿⣿⣿⣿⠿⠛⠁⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⣿⡿⠟⠋⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⠈⠙⠻⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⣤⣤⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣤⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢹⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⡀⠀⠀⠀⢀⣀⣀⡀⠀⠀⠀⣀⣀⠀⠀⠀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣸⣿⣿⣿⣀⣀⣀⡀⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⢀⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⠀⣴⣾⣿⣿⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠀⣤⣾⣿⣿⣿⣿⣿⣿⣿⣶⡄⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⣿⣄⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣸⣿⣿⣿⠀⠀⠀⠀⣠⣿⣿⣿⠟⠋⠁⠀⠀⠀⠉⠻⣿⣿⣿⡄⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⣼⡿⠟⠋⠉⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⣸⣿⣿⡿⠉⠀⠀⠈⠙⢿⣿⣿⡄⠀⠀⠉⠉⠉⢹⣿⣿⣿⠉⠉⠉⠁⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⣶⣶⣶⣶⡆⠀⠀⠀⠀⣶⣶⣶⣶⡆⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⢠⣿⣿⣿⣃⣀⣀⣀⣀⣀⣀⣀⣀⣸⣿⣿⣿⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠹⣿⣿⣷⣤⣀⡀⠀⠀⠈⠉⠉⠁⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⣿⣿⣿⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⢹⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠀⠉⠛⠿⣿⣿⣿⣿⣶⣦⣤⡀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠘⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⣀⣀⡀⠀⠀⠀⠉⠉⠛⢿⣿⣿⣦⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⡇⠀⠀⠀⠀⣿⣿⣿⣿⠁⠀⠀⠀⠀⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠹⣿⣿⣿⣦⣀⠀⠀⠀⠀⠀⣠⣾⣿⣿⡟⠀⠀⠀⢹⣿⣿⣿⣄⡀⠀⠀⠀⣀⣴⡿⢹⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡇⠀⠀⠈⣿⣿⣿⣆⡀⠀⠀⠀⠀⣸⣿⣿⣿⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⣿⣿⣿⣿⣷⣦⣄⠀⠀⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⢀⣠⣶⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠈⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀⢸⣿⣿⣿⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⡇⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⠙⠻⢿⣿⣿⣿⣿⣿⣶⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⠀⠀⠀⣀⣤⣾⣿⣿⣿⣿⣿⡿⠟⠁⠀⠀⠀⠀⠀⠀⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠙⠛⠛⠛⠋⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠛⠛⠛⠉⠀⠀⠀⠈⠉⠉⠉⠀⠀⠀⠈⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠉⠙⠛⠛⠛⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⠀⠀⠀⠉⠛⠿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣤⣴⣿⣿⣿⣿⣿⣿⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠻⢿⣿⣿⣿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠿⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀"
            ;;
       # *)
       #     figlet -f "$font" -w "$width" "$text"
       #     ;;
    esac
}

prompt_evm_addresses() {
    # apt-get install -y figlet >/dev/null 2>&1
    # Generate ASCII art
    echo "${GREEN}"
    #generate_ascii_art "Heurist"
    echo "${NC}"
    echo "${BLUE}"
    generate_ascii_art "Symbol"
    echo "${NC}"
    
        printf "${BLUE}\\nYour instance has %s with %d GPUs.\\n${NC}" "$gpu_model" "$num_gpus"
        printf "${GREEN}\\n%s\\n${NC}" "$heurist_ascii_art"
        printf "${BLUE}Your System Configuration is:\\n${NC}"
        print_table "$gpu_model" "$num_gpus" "$vram_info"
        printf "${BLUE}\\n\\nBased on the System Configuration, The Recommended models to run are:\\n${NC}"
        printf "${GREEN}\\n${NC}"
        print_multiplier_table "$rec_llm_model" "$rec_sd_model"
        printf "${ITALICS}${GREEN}\\nPress 'Y' to continue with the recommended miner setup, Press 'N' to choose setup manually:${NC} "
        read user_choice
        if [ "$user_choice" != "n" ] && [ "$user_choice" != "N" ] && [ "$user_choice" != "y" ] && [ "$user_choice" != "Y" ]; then
            echo "${RED}Invalid choice. Please enter 'Y' or 'N'.${NC}"
        else
            break
        fi
    

    
    
    if [ "$num_gpus" -gt 1 ]; then
        #printf "${BLUE}\\nYour instance has $gpu_model with %s GPUs.\\n${NC}" "$num_gpus"
        #printf "${BLUE}\\nYour instance has %s with %d GPUs.\\n${NC}" "$gpu_model" "$num_gpus"

        while true; do
            printf "${ITALICS}${GREEN}\nEnter a single EVM address for all GPUs or provide %s distinct addresses separated by a comma:${NC}\\n " "$num_gpus"
            read evm_addresses
            if [ -z "$evm_addresses" ]; then
                echo "${RED}Error: EVM addresses cannot be empty.${NC}"
            else
                break
            fi
        done

        case "$evm_addresses" in
            *,*)
                num_addresses=$(echo "$evm_addresses" | tr ',' '\n' | wc -l)
                if [ "$num_addresses" -ne "$num_gpus" ]; then
                    printf "Error: The number of provided EVM addresses does not match the number of GPUs (%s).\\n" "$num_gpus" >&2
                    exit 1
                fi
                set -- $(echo "$evm_addresses" | tr ',' ' ')
                i=0
                for address; do
                    eval "address_$i='$address'"
                    i=$(expr "$i" + 1)
                done
                ;;
            *)
                i=0
                while [ "$i" -lt "$num_gpus" ]; do
                    eval "address_$i='$evm_addresses'"
                    i=$(expr "$i" + 1)
                done
                ;;
        esac
    else
        while true; do
            printf "${ITALICS}${GREEN}\\nPlease enter your EVM_Address:${NC} "
            read evm_address
            if [ -z "$evm_address" ]; then
                echo "${RED}Error: EVM address cannot be empty.${NC}"
            else
                break
            fi
        done
    fi
}

prompt_miner_config() {
if [ "$user_choice" = "n" ] || [ "$user_choice" = "N" ]; then
        echo "${GREEN}\\nChoose the appropriate miners you want to run\\n${NC}"
        echo "1.⛏️ Both LLM & SD (Exclude SDL) --( 🦙,🧚‍♀️ ) Required VRAM of 24GB - 48GB$(if [ "$recommended_mining_option" = "1" ]; then echo "${BLUE}      💎   Recommended based on system config${NC}"; fi)"
        echo "2.⛏️ Both LLM & SD (Include SDL) --( 🦙,🧚‍♀️,🧚‍♀️ ) Required VRAM of 24GB - 48GB- 48GB$(if [ "$recommended_mining_option" = "2" ]; then echo "${BLUE}      💎   Recommended based on system config${NC}"; fi)"
        echo "3.⛏️ Only LLM Miner --( 🦙 ) Required VRAM of 24GB - 48GB$(if [ "$recommended_mining_option" = "3" ]; then echo "${BLUE}      💎  Recommended based on system config${NC}"; fi)"
        echo "4.⛏️ Only SD Miner  --( 🧚‍♀️🧚‍♀️ ) Required VRAM of 12GB$(if [ "$recommended_mining_option" = "4" ]; then echo "${BLUE}      💎  Recommended based on system config${NC}"; fi)"

        while true; do
            printf "${ITALICS}${GREEN}\\nEnter your choice (1/2/3/4):${NC} "
            read miner_choice
            if [ "$miner_choice" != "1" ] && [ "$miner_choice" != "2" ] && [ "$miner_choice" != "3" ] && [ "$miner_choice" != "4" ]; then
echo "${RED}Invalid choice. Please enter 1, 2, 3, or 4.${NC}"
else
break
fi
done

if [ "$miner_choice" = "1" ] || [ "$miner_choice" = "2" ] || [ "$miner_choice" = "3" ]; then
        echo "${GREEN}\\n\\nWhich LLM Miner model do you want to run?\\n${NC}"
        echo "1. openhermes-2.5-mistral-7b-gptq (8 Bit-12GB RAM  0.1X Reward 🦙 )$(if [ "$recommended_llm_model" = "1" ]; then echo "${BLUE}      💎  Recommended based on system config${NC}"; fi)"
        echo "2. openhermes-2-pro-mistral-7b (16-Bit-24GB RAM  0.2X Reward 🦙,🦙 )$(if [ "$recommended_llm_model" = "2" ]; then echo "${BLUE}      💎 Recommended based on system config${NC}"; fi)"
        echo "3. openhermes-mixtral-8x7b-gptq(4 Bit-48GB RAM 1x Reward  🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙 )$(if [ "$recommended_llm_model" = "3" ]; then echo "${BLUE}      💎  Recommended based on system config${NC}"; fi)"
        echo "4. openhermes-2-yi-34b-gptq (8 Bit- 48GB RAM 1X Reward  🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙,🦙 )$(if [ "$recommended_llm_model" = "4" ]; then echo "${BLUE}      💎  Recommended based on system config${NC}"; fi)"

        while true; do
            printf "${ITALICS}${GREEN}\\nEnter your choice (1/2/3/4):${NC} "
            read llm_model_choice
            if [ "$llm_model_choice" != "1" ] && [ "$llm_model_choice" != "2" ] && [ "$llm_model_choice" != "3" ] && [ "$llm_model_choice" != "4" ]; then
                echo "${RED}Invalid choice. Please enter 1, 2, 3, or 4.${NC}"
            else
                break
            fi
        done

        case $llm_model_choice in
            1) llm_miner_command="./llm-miner-starter.sh openhermes-2.5-mistral-7b-gptq" ;;
            2) llm_miner_command="./llm-miner-starter.sh openhermes-2-pro-mistral-7b" ;;
            3) llm_miner_command="./llm-miner-starter.sh openhermes-mixtral-8x7b-gptq" ;;
            4) llm_miner_command="./llm-miner-starter.sh openhermes-2-yi-34b-gptq" ;;
        esac
    fi

    if [ "$miner_choice" = "1" ] || [ "$miner_choice" = "2" ] || [ "$miner_choice" = "3" ]; then
    printf "${ITALICS}${GREEN}\\nIf you want to modify Child Processes, please enter the number, Press Enter to retain the default value\\n${NC}"
    read num_child_process
    fi
    
else
    echo "${GREEN}\\nYou have a $gpu_model with $num_gpus GPUs and $vram_info RAM.${NC}"
    echo "${GREEN}\\nBased on the system resources:Executing $(if [ "$recommended_mining_option" = "1" ] || [ "$recommended_mining_option" = "2" ]; then
                        case "$rec_llm_miner_cmd" in
                            "./llm-miner-starter.sh openhermes-2.5-mistral-7b-gptq")
                                echo "$llm_1"
                                ;;
                            "./llm-miner-starter.sh openhermes-2-pro-mistral-7b")
                                echo "$llm_2"
                                ;;
                            "./llm-miner-starter.sh openhermes-mixtral-8x7b-gptq")
                                echo "$llm_3"
                                ;;
                            "./llm-miner-starter.sh openhermes-2-yi-34b-gptq")
                                echo "$llm_4"
                                ;;
                        esac
                        echo "on $num_gpus GPU's followed by"
                    fi) \
                    $(if [ "$recommended_mining_option" = "1" ]; then
                        echo "$sdm_sdxl"
                    elif [ "$recommended_mining_option" = "2" ] || [ "$recommended_mining_option" = "4" ]; then
                        echo "$sdm"
                    fi)"${NC}

    sleep 5
    num_child_process=25
fi
}

install_stable_diffusion_packages() {
echo "${GREEN}\n✓Installing packages required for Stable Diffusion\n${NC}"
 apt update &&  apt upgrade -y
 apt install nano 
 apt install tmux -y
 apt install curl -y
 #apt-get install python3.8-venv
 python3 --version | awk -F'[ .]' '{if ($2 < 3 || ($2 == 3 && $3 < 9)) system("apt-get install -y python3.8-venv")}'
 apt install wget
echo "${GREEN}✓ Packages Updated → Creating New Conda Environment${NC}"
conda create --name gpu-3-11 python=3.11 -y
echo "${GREEN}\n✓ New Conda Environment Created → Initializing Conda\n${NC}"

eval "$(conda shell.posix hook)"
echo "${GREEN}\n✓ Conda Initialized → Activating Conda Environment\n${NC}"

conda activate /opt/conda/envs/gpu-3-11
echo "${GREEN}\n✓ Conda Environment Activated → Cloning Miner-Release Repository\n${NC}"

git clone https://github.com/heurist-network/miner-release
echo "${GREEN}\n✓ Miner-Release Repository Cloned → Changing Directory\n${NC}"


CONFIG_FILE=$(find / -type f -name "config.toml" -path "*/miner-release/*" -print -quit)

cd miner-release/
echo "${GREEN}\n✓ Directory Changed to Miner-Release → Creating .env File\n${NC}"

pip install python-dotenv
   
update_sd_miner_command

touch .env
echo "${GREEN}\n✓ .env File Created → Opening .env File for Editing\n${NC}"

if [ "$num_gpus" -gt 1 ]; then
    case "$evm_addresses" in
        *,*)
            set -- $(echo "$evm_addresses" | tr ',' ' ')
            i=0
            for address; do
                echo "MINER_ID_$i=$address" >> .env
                i=$((i + 1))
            done
            ;;
        *)
            i=0
            while [ "$i" -lt "$num_gpus" ]; do
                echo "MINER_ID_$i=$evm_addresses" >> .env
              i=$((i + 1))
            done
            ;;
    esac
else
    echo "MINER_ID_0=$evm_address" >> .env
fi

echo "${GREEN}\n✓ .env File Updated with EVM_Address → Installing Requirements\n${NC}"

yes | pip install -r requirements.txt
echo "${GREEN}\n✓ Requirements Installed\n${NC}"

sed -i "s/^num_cuda_devices =.*/num_cuda_devices = $num_gpus/" "$CONFIG_FILE"
if [ -n "$num_child_process" ]; then
    sed -i "s/^num_child_process =.*/num_child_process = $num_child_process/" "$CONFIG_FILE"
    sed -i "s/^concurrency_soft_limit =.*/concurrency_soft_limit = $((num_child_process + 10))/" "$CONFIG_FILE"
fi
echo "${GREEN}\nUpdated num_child_process and concurrency_soft_limit in .env file and num_cuda_devices in config.toml.\n${NC}"
}

install_llm_packages() {
echo "${GREEN}\nInstalling Packages required for LLM Miner\n${NC}"
 apt update -y &&  apt install -y jq
echo "${GREEN}\n✓ jq Installed → Installing bc\n${NC}"
 apt install -y bc

#echo "${GREEN}\n✓ bc Installed → Updating Packages\n${NC}"

 apt update -y &&  apt upgrade -y &&  apt install -y software-properties-common &&  add-apt-repository ppa:deadsnakes/ppa << EOF

EOF
 apt install -y python3-venv
echo "${GREEN}\n✓ Dependencies Installed for LLM Miner\n${NC}"
}

run_miners() {
    tmux new-session -d -s miner_monitor

    max_panes=0
    if [ "$user_choice" = "n" ] || [ "$user_choice" = "N" ]; then
        if [ "$miner_choice" = "1" ] || [ "$miner_choice" = "2" ]; then
            max_panes=$((num_gpus + 1))
        elif [ "$miner_choice" = "3" ]; then
            max_panes=$num_gpus
        elif [ "$miner_choice" = "4" ]; then
            max_panes=1
        fi
    else
        if [ "$recommended_mining_option" = "1" ] || [ "$recommended_mining_option" = "2" ]; then
            max_panes=$((num_gpus + 1))
        elif [ "$recommended_mining_option" = "3" ]; then
            max_panes=$num_gpus
        elif [ "$recommended_mining_option" = "4" ]; then
            max_panes=1
        fi
    fi

    if [ "$user_choice" = "n" ] || [ "$user_choice" = "N" ]; then
        if [ "$miner_choice" = "1" ] || [ "$miner_choice" = "2" ] || [ "$miner_choice" = "3" ]; then
            for i in $(seq 0 $((num_gpus - 1))); do
                gpu_uuid=$(nvidia-smi --query-gpu=index,uuid --format=csv,noheader | awk -F', ' -v idx="$i" '$1 == idx {print substr($2, 5, 6)}')
                miner_id=$(eval echo "\$address_$i")
                log_file="llm-miner_${miner_id}-${gpu_uuid}.log"

                if [ "$i" -eq 0 ]; then
                    tmux send-keys -t miner_monitor "$llm_miner_command --miner-id-index $i --port 800$i --gpu-ids $i" C-m
                else
                    tmux split-window -v -t miner_monitor
                    tmux select-layout -t miner_monitor tiled
                    prev_gpu_uuid=$(nvidia-smi --query-gpu=index,uuid --format=csv,noheader | awk -F', ' -v idx="$((i-1))" '$1 == idx {print substr($2, 5, 6)}')
                    prev_miner_id=$(eval echo "\$address_$((i-1))")
                    prev_log_file="llm-miner_${prev_miner_id}-${prev_gpu_uuid}.log"

                    tmux send-keys -t miner_monitor.$((i)) "while true; do if [ -f \"$prev_log_file\" ]; then if grep -q '.*LLM miner started.*' \"$prev_log_file\"; then break; else sleep 1; fi; else sleep 1; fi; done" C-m
                    tmux send-keys -t miner_monitor.$((i)) "clear;echo 'Waiting for LLM to start in GPU $((i-1))...'" C-m
                    tmux send-keys -t miner_monitor.$((i)) "echo 'LLM started in GPU $((i-1)). Starting LLM in GPU $i...'" C-m
                    tmux send-keys -t miner_monitor.$((i)) "$llm_miner_command --miner-id-index $i --port 800$i --gpu-ids $i" C-m
                fi
                pane_index=$((pane_index + 1))
            done

            if [ "$miner_choice" = "1" ] || [ "$miner_choice" = "2" ]; then
                tmux split-window -v -t miner_monitor
                tmux select-layout -t miner_monitor tiled
                last_pane_index=$num_gpus
                if [ "$num_gpus" -eq 1 ]; then
                    gpu_uuid=$(nvidia-smi --query-gpu=index,uuid --format=csv,noheader | awk -F', ' '$1 == 0 {print substr($2, 5, 6)}')
                    miner_id="$evm_address"
                else
                    gpu_uuid=$(nvidia-smi --query-gpu=index,uuid --format=csv,noheader | awk -F', ' -v idx="$((last_pane_index-1))" '$1 == idx {print substr($2, 5, 6)}')
                    miner_id=$(eval echo "\$address_$((last_pane_index-1))")
                fi
                log_file="llm-miner_${miner_id}-${gpu_uuid}.log"

                tmux send-keys -t miner_monitor.$((last_pane_index)) "while true; do if [ -f \"$log_file\" ]; then if grep -q '.*LLM miner started.*' \"$log_file\"; then break; else sleep 1; fi; else sleep 1; fi; done" C-m
                tmux send-keys -t miner_monitor.$((last_pane_index)) "clear;echo 'Waiting for LLM to start in GPU $((last_pane_index-1))...'" C-m
                tmux send-keys -t miner_monitor.$((last_pane_index)) "echo 'LLM started in GPU $((last_pane_index-1)). Starting SD Miner...'" C-m
                tmux send-keys -t miner_monitor.$((last_pane_index)) "$CONDA_ACTIVATE" C-m
                tmux send-keys -t miner_monitor.$((last_pane_index)) "$sd_miner_command" C-m
            fi
        elif [ "$miner_choice" = "4" ]; then
            tmux send-keys -t miner_monitor "$CONDA_ACTIVATE" C-m
            tmux send-keys -t miner_monitor "$sd_miner_command" C-m
        fi
    else
        if [ "$recommended_mining_option" = "1" ] || [ "$recommended_mining_option" = "2" ] || [ "$recommended_mining_option" = "3" ]; then
            for i in $(seq 0 $((num_gpus - 1))); do
                gpu_uuid=$(nvidia-smi --query-gpu=index,uuid --format=csv,noheader | awk -F', ' -v idx="$i" '$1 == idx {print substr($2, 5, 6)}')
                miner_id=$(eval echo "\$address_$i")
                log_file="llm-miner_${miner_id}-${gpu_uuid}.log"

                if [ "$i" -eq 0 ]; then
                    tmux send-keys -t miner_monitor "$rec_llm_miner_cmd --miner-id-index $i --port 800$i --gpu-ids $i" C-m
                else
                    tmux split-window -v -t miner_monitor
                    tmux select-layout -t miner_monitor tiled
                    prev_gpu_uuid=$(nvidia-smi --query-gpu=index,uuid --format=csv,noheader | awk -F', ' -v idx="$((i-1))" '$1 == idx {print substr($2, 5, 6)}')
                    prev_miner_id=$(eval echo "\$address_$((i-1))")
                    prev_log_file="llm-miner_${prev_miner_id}-${prev_gpu_uuid}.log"

                    tmux send-keys -t miner_monitor.$((i)) "while true; do if [ -f \"$prev_log_file\" ]; then if grep -q '.*LLM miner started.*' \"$prev_log_file\"; then break; else sleep 1; fi; else sleep 1; fi; done" C-m
                    tmux send-keys -t miner_monitor.$((i)) "clear;echo 'Waiting for LLM to start in GPU $((i-1))...'" C-m
                    tmux send-keys -t miner_monitor.$((i)) "echo 'LLM started in GPU $((i-1)). Starting LLM in GPU $i...'" C-m
                    tmux send-keys -t miner_monitor.$((i)) "$rec_llm_miner_cmd --miner-id-index $i --port 800$i --gpu-ids $i" C-m
                fi
                pane_index=$((pane_index + 1))
            done

            if [ "$recommended_mining_option" = "1" ] || [ "$recommended_mining_option" = "2" ]; then
                tmux split-window -v -t miner_monitor
                tmux select-layout -t miner_monitor tiled
                last_pane_index=$num_gpus
                if [ "$num_gpus" -eq 1 ]; then
                    gpu_uuid=$(nvidia-smi --query-gpu=index,uuid --format=csv,noheader | awk -F', ' '$1 == 0 {print substr($2, 5, 6)}')
                    miner_id="$evm_address"
                else
                    gpu_uuid=$(nvidia-smi --query-gpu=index,uuid --format=csv,noheader | awk -F', ' -v idx="$((last_pane_index-1))" '$1 == idx {print substr($2, 5, 6)}')
                    miner_id=$(eval echo "\$address_$((last_pane_index-1))")
                fi
                log_file="llm-miner_${miner_id}-${gpu_uuid}.log"

                tmux send-keys -t miner_monitor.$((last_pane_index)) "while true; do if [ -f \"$log_file\" ]; then if grep -q '.*LLM miner started.*' \"$log_file\"; then break; else sleep 1; fi; else sleep 1; fi; done" C-m
                tmux send-keys -t miner_monitor.$((last_pane_index)) "clear;echo 'Waiting for LLM to start in GPU $((last_pane_index-1))...'" C-m
                tmux send-keys -t miner_monitor.$((last_pane_index)) "echo 'LLM started in GPU $((last_pane_index-1)). Starting SD Miner...'" C-m
                tmux send-keys -t miner_monitor.$((last_pane_index)) "$CONDA_ACTIVATE" C-m
                tmux send-keys -t miner_monitor.$((last_pane_index)) "$rec_sd_miner_cmd" C-m
            fi
        elif [ "$recommended_mining_option" = "4" ]; then
            tmux send-keys -t miner_monitor "$CONDA_ACTIVATE" C-m
            tmux send-keys -t miner_monitor "$rec_sd_miner_cmd" C-m
        fi
    fi

    tmux attach-session -t miner_monitor
}


update_tmux_bashrc_conf() {
if [ -f ~/.tmux.conf ]; then
    grep -q 'setw -g mode-keys vi' ~/.tmux.conf || echo 'setw -g mode-keys vi' >> ~/.tmux.conf
    grep -q 'set -g status-keys vi' ~/.tmux.conf || echo 'set -g status-keys vi' >> ~/.tmux.conf
    grep -q 'set -g mouse on' ~/.tmux.conf || echo 'set -g mouse on' >> ~/.tmux.conf
else
    echo 'setw -g mode-keys vi' >> ~/.tmux.conf
    echo 'set -g status-keys vi' >> ~/.tmux.conf
    echo 'set -g mouse on' >> ~/.tmux.conf
fi

if ! grep -q "alias monitor='tmux attach-session -t miner_monitor'" ~/.bashrc; then
    echo "alias monitor='tmux attach-session -t miner_monitor'" >> ~/.bashrc

fi

}

#==========================Main Program=============================================#

#update_sd_miner_command
detect_gpus
# Call the recommend_models function here
recommend_models

#Address prompt
prompt_evm_addresses

#Mining choices Prompt
prompt_miner_config

#Install SD Packages
install_stable_diffusion_packages

#Install LLM Packages if selected
if [ "$miner_choice" = "1" ] || [ "$miner_choice" = "2" ] || [ "$miner_choice" = "3" ] || [ "$recommended_mining_option" = "1" ] || [ "$recommended_mining_option" = "2" ] || [ "$recommended_mining_option" = "3" ]; then
    install_llm_packages
fi


#Enable vi mode and set scroll on for tmux
update_tmux_bashrc_conf

#Execution logic
run_miners

#Restart bash to update bashrc
exec bash

