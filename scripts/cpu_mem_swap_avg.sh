#! /usr/bin/env bash

# Description: 采集CPU、swap、内存信息

cpu_total=''    # cpu总量 (单位MHz)
cpu_used=''     # CPU使用 (单位MHz)
cpu_usage=''    # cpu使用率

swap_total=''   # swap总量 (单位Kb)
swap_used=''    # swap使用 = swap总量 - free部分的swap(单位Kb)
swap_usage=''   # swap使用率 = (swap使用/swap总量) * 100

mem_total=''    # 内存总量 (单位Kb)
mem_used=''     # 内存使用 = 内存总量-free部分的内存(单位Kb)
mem_usage=''    # 内存使用率 = 内存使用/内存总量 * 100


function GetCPUInfo(){
    # CPU 总大小
    cpu_total=$(cat /proc/cpuinfo | grep 'cpu MHz' | awk '{sum+=$NF}END{printf ("%d",sum+0.5)}')
    
    # CPU 使用情况
    # 方式一: 每 5s 取一次CPU数据, 共取5次, 求平均值
    # cpu_usage=$(sar -u 5 5 | grep 'Average' | awk '{printf ("%d",100-$NF+0.5)}')
    # 方式二: 只取1次数据
    read cpu_usage cpu_used <<< $(sar -u 1 1 | grep 'Average' | awk '{printf ("%.5s %d",100-$NF,(100-$NF)*"'$cpu_total'"/100)}')

}


function GetMemInfo(){
    # 内存总大小
    mem_total=$(cat /proc/meminfo | grep 'MemTotal' | awk -F' ' '{print $(NF-1)}')

    # 内存使用情况
    # 方式一: 每 5s 取一次内存数据, 共取 5 次；然后取 5 次数据的平均值
    # mem_used_list=( $(for i in {0..4}; do cat /proc/meminfo | grep 'MemFree' | awk -F' ' '{printf ( "%d ","'$mem_total'"-$(NF-1) )}'; sleep 5; done) )
    # mem_used=$(echo ${mem_used_list[*]} | tr ' ' '\n'|awk '{sum+=$1}END{print sum/NR}')
    # mem_usage_list=( $(for i in ${mem_used_list[*]}; do expr $i \* 100 / $mem_total; done) )
    # mem_usage=$(echo ${mem_usage_list[*]} | tr ' ' '\n'|awk '{sum+=$1}END{print sum/NR}')
    #
    # 方式二: 只取1次数据
    mem_used=$(cat /proc/meminfo | grep 'MemFree' | awk -F' ' '{printf ( "%d ","'$mem_total'"-$(NF-1) )}')
    mem_usage=$(echo $mem_used | awk '{printf ("%.5s", $1/"'$mem_total'"*100)}')
}


function GetSwapInfo(){
    # Swap 总大小
    swap_total=$(cat /proc/meminfo | grep 'SwapTotal' | awk -F' ' '{print $(NF-1)}')

    # Swap 使用情况
    # 方式一: 每 5s 取一次 swap 数据, 共取 5 次；然后取 5 次数据的平均值
    # swap_used_list=( $(for i in {0..4}; do cat /proc/meminfo | grep 'SwapFree' | awk -F' ' '{printf ( "%d ","'$swap_total'"-$(NF-1) )}'; sleep 5; done) )
    # swap_usage_list=( $(for i in ${swap_used_list[*]}; do expr $i \* 100 / $swap_total; done) )
    # swap_used=$(echo ${swap_used_list[*]} | tr ' ' '\n'|awk '{sum+=$1}END{print sum/NR}')
    # swap_usage=$(echo ${swap_usage_list[*]} | tr ' ' '\n'|awk '{sum+=$1}END{print sum/NR}')
    # 
    # 方式二: 只取1次数据
    swap_used=$(cat /proc/meminfo | grep 'SwapFree' | awk -F' ' '{printf ( "%d ","'$swap_total'"-$(NF-1) )}')
    swap_usage=$(echo $swap_used | awk '{printf ("%.5s", $1/"'$swap_total'"*100)}')

}



function main(){
    GetCPUInfo
    GetMemInfo
    GetSwapInfo
    # json格式输出
    echo {'"'cpu_total'"': '"'$cpu_total'"', '"'cpu_used'"': '"'$cpu_used'"', '"'cpu_usage'"': '"'$cpu_usage'"', '"'swap_total'"': '"'$swap_total'"', '"'swap_used'"': '"'$swap_used'"', '"'swap_usage'"': '"'$swap_usage'"', '"'mem_total'"': '"'$mem_total'"', '"'mem_used'"': '"'$mem_used'"', '"'mem_usage'"': '"'$mem_usage'"'}
}


main
