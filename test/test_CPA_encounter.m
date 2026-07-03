close all; clear; clc;
addpath('../src');

% 1. 模拟AIS数据输入
OS = [120.00, 30.00, 15.0, 0.0];    % 本船：航向000度，速度15节
TS = [120.01, 30.08, 12.0, 180.0];  % 他船：航向180度，速度12节，在本船正前方偏东驶来

% 2. 模块一：计算 DCPA 和 TCPA
[dcpa, tcpa, d_current] = CPA(OS, TS);

% 3. 模块二：判断局面并输出决策
action_cmd = case_encounter(OS, TS, dcpa, tcpa);

% 打印结果
fprintf('DCPA: %.2f nm, TCPA: %.2f min\n', dcpa, tcpa);
switch action_cmd
    case 1
        fprintf('>>> 决策指令: 1 (存在危险，对遇或右舷交叉，向右转)\n');
    case -1
        fprintf('>>> 决策指令: -1 (存在危险，特殊交叉或追越，向左转)\n');
    case 0
        fprintf('>>> 决策指令: 0 (安全或作为直航船，直行保向)\n');
end