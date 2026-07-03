close all; clear; clc;

%% 1. 初始化船舶状态数据 
os_init = [122.0000, 30.0000, 15, 000]; 
ts_init = [122.1155, 30.1250, 12, 270];

%% 2. 规则判断

[DCPA_init, TCPA_init] = CPA(os_init, ts_init);
K = case_encounter(os_init, ts_init, DCPA_init, TCPA_init); 
if K == 0
    disp('无需避让，保持原航线航行。');
    return;
end

%% 3. GA 参数与边界设置
num_vars = 4; % 变量: [直航时间, 避让角度, 避让时间, 复航角度]
lb = [0, 1, 0,  1];   
ub = [90, 90, 90, 90];  

% 适应度计算
FitnessFcn = @(x) fitness(x, os_init, ts_init, K);

options = optimoptions('gamultiobj', ...
    'PopulationSize', 100, ...         
    'MaxGenerations', 60, ...          
    'ParetoFraction', 0.35, ...        
    'Display', 'final');         

%% 4. 运行优化
disp('开始运行 方案A 优化算法...');
[x_pareto, fval_pareto] = gamultiobj(FitnessFcn, num_vars, ...
    [], [], [], [], lb, ub, [], options);

%% 新增：自定义绘制符合航海直觉的帕累托前沿图
if ~isempty(fval_pareto)
    figure('Name', '帕累托最优决策前沿', 'Color', 'w');
    
    % 提取并转换物理量
    total_time = fval_pareto(:, 1);    % X轴：总耗时（分钟），越小越好
    actual_dcpa = -fval_pareto(:, 2);  % Y轴：乘以-1，变回正的实际DCPA（海里），越大越好
    
    % 绘制帕累托前沿点
    plot(total_time, actual_dcpa, 'o', 'MarkerSize', 6, 'LineWidth', 1.5);
    hold on;
    grid on;
    
    % 绘制你设定的安全距离基准线
    d_safe_line = 1.0;
    xl = xlim;
    line(xl, [d_safe_line, d_safe_line], 'Color', [0.8 0.2 0.2], 'LineStyle', '--', 'LineWidth', 1.5);
    text(xl(1) + 0.1*(xl(2)-xl(1)), d_safe_line + 0.1, '安全距离门槛', 'Color', [0.8 0.2 0.2]);
    
    % 美化坐标轴标签
    xlabel('经济性指标：总航行耗时 (分钟) [越小越好]');
    ylabel('安全性指标：实际最小会遇距离 (海里) [越大越好]');
    title('船舶避碰决策帕累托前沿分布图');
    
    % 调整坐标轴纵向范围，让人一眼看清安全区域
    ylim([0, max(actual_dcpa) + 0.5]);
end