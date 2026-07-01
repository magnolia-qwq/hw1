clear; clc; close all;

%% 1. 参数设置
pop_size = 50;      % 种群大小 (Population Size)
max_gen = 100;      % 最大迭代次数 (Max Generations)
pc = 0.8;           % 交叉概率 (Crossover Probability)
pm = 0.1;           % 变异概率 (Mutation Probability)
var_num = 3;        % 变量个数
Lb = [-3, -3, -3];% 变量下界 (Lower Bound)
Ub = [3, 3, 3];   % 变量上界 (Upper Bound)
stall_limit = 15;   % 连续 x 代没有明显改善就终止
tol_value = 1e-6;   % 改善的容差阈值
stall_counter = 0;  % 停滞计数器

%% 2. 初始化种群
Pop = repmat(Lb, pop_size, 1) + repmat((Ub - Lb), pop_size, 1) .* rand(pop_size, var_num);

%% 3. 适应度函数设定
fitness_func = @(v) (v(:,1).^2 + v(:,2).^2 + sin(v(:,3))); %f(x)=x^2+y^2+sinz

%% 4. 遗传算法主循环
best_fitness = zeros(max_gen, 1);     % 记录历代最优适应度
best_chrom = zeros(max_gen, var_num); % 记录历代最优个体

for gen = 1:max_gen
    % --- A. 评估当前种群适应度 ---
    fit = fitness_func(Pop);
    [sorted_fit, sort_idx] = sort(fit, 'descend'); 
    
    current_best = sorted_fit(1);
    
    % --- 检查是否比上一代有所进步 ---
    if gen > 1
        if (current_best - best_fitness(gen-1)) > tol_value
            stall_counter = 0;
        else
            stall_counter = stall_counter + 1;
        end
    end
    
    % 记录历代最优
    best_fitness(gen) = current_best;
    best_chrom(gen, :) = Pop(sort_idx(1), :);

    % --- 终止阈值判断 ---
    if stall_counter >= stall_limit
        fprintf('算法在第 %d 代触发终止阈值（连续 %d 代无明显改善），提前结束。\n', gen, stall_limit);
        best_fitness(gen+1:end) = [];
        best_chrom(gen+1:end, :) = [];
        break; 
    end
    
    % --- B. 选择操作 (轮盘赌) ---
    % 1. 平移映射
    fit_positive = fit - min(fit) + 0.01; 
    % 2. 计算每个个体的选中概率
    prob = fit_positive / sum(fit_positive);
    % 3. 计算累加概率
    cum_prob = cumsum(prob);
    
    new_Pop = zeros(size(Pop));
    for i = 1:pop_size
        r = rand;
        % 寻找第一个累加概率大于 r 的个体索引
        idx = find(cum_prob >= r, 1, 'first'); 
        new_Pop(i, :) = Pop(idx, :);
    end
    Pop = new_Pop;
    
    % --- C. 交叉操作 ---
    for i = 1:2:pop_size-1
        if rand < pc
            swap_dim = randi([1, var_num]); 
            temp = Pop(i, swap_dim);
            Pop(i, swap_dim) = Pop(i+1, swap_dim);
            Pop(i+1, swap_dim) = temp;
        end
    end
    
    % --- D. 变异操作 ---
    for i = 1:pop_size
        for j = 1:var_num
            if rand < pm
                Pop(i, j) = Lb(j) + (Ub(j) - Lb(j)) * rand;
            end
        end
    end
end

%% 5. 结果分析与可视化
[global_max, best_gen] = max(best_fitness);
optimal_vars = best_chrom(best_gen, :);
actual_gen = length(best_fitness); 

% 绘制收敛曲线
figure('Color', 'w');
plot(1:actual_gen, best_fitness, 'LineWidth', 2, 'Color', '#D95319');
title('GA 收敛曲线', 'FontSize', 14);
xlabel('迭代次数 (Generation)', 'FontSize', 12);
ylabel('最优适应度值 (Best Fitness)', 'FontSize', 12);
grid on;

% 命令行输出结果
fprintf('\n=== GA 优化完成 ===\n');
fprintf('实际运行代数: %d / %d\n', actual_gen, max_gen);
fprintf('最优变量取值: x = %.4f, y = %.4f, z = %.4f\n', optimal_vars(1), optimal_vars(2), optimal_vars(3));
fprintf('最大适应度值: %.4f\n', global_max);