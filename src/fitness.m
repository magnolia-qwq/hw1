function f = fitness(x, os_init, ts_init, K)
    % 编码基因说明 (4个变量，单位: 分钟 和 度):
    % x(1): 直航时间 (t_straight)
    % x(2): 避让转向角度绝对值 (theta_avoid)
    % x(3): 避让时间 (t_avoid)
    % x(4): 复航角度绝对值 (theta_return) 
    
    %% --- 提取变量与参数 ---
    t_straight = x(1);
    theta_avoid = x(2);
    t_avoid = x(3);
    theta_return = x(4);
    
    lon_o = os_init(1); lat_o = os_init(2); v_o = os_init(3); c_o = os_init(4);
    lon_t = ts_init(1); lat_t = ts_init(2); v_t = ts_init(3); c_t = ts_init(4);
    
    % 各阶段航向
    avoid_course = c_o + K * theta_avoid;
    return_course = c_o - K * theta_return;
    
    % 衍生复航时间 (分钟)
    t_return = t_avoid * (sind(theta_avoid) / sind(theta_return));

    %% --- 节点坐标与状态推算 ---
    h_straight = t_straight / 60; 
    h_avoid = t_avoid / 60;       
    h_return = t_return / 60;
    
    % 1. 节点 A 推算 (直航结束 -> 开始避让)
    d_t_straight = v_t * h_straight; 
    lat_t_A = lat_t + (d_t_straight * cosd(c_t)) / 60;
    lon_t_A = lon_t + (d_t_straight * sind(c_t)) / (60 * cosd((lat_t + lat_t_A)/2));
    
    d_o_straight = v_o * h_straight;
    lat_o_A = lat_o + (d_o_straight * cosd(c_o)) / 60;
    lon_o_A = lon_o + (d_o_straight * sind(c_o)) / (60 * cosd((lat_o + lat_o_A)/2));
    
    os_A = [lon_o_A, lat_o_A, v_o, avoid_course];
    ts_A = [lon_t_A, lat_t_A, v_t, c_t];
    
    % 2. 节点 B 推算 (避让结束 -> 开始复航)
    d_t_avoid = v_t * h_avoid;
    lat_t_B = lat_t_A + (d_t_avoid * cosd(c_t)) / 60;
    lon_t_B = lon_t_A + (d_t_avoid * sind(c_t)) / (60 * cosd((lat_t_A + lat_t_B)/2));
    
    d_o_avoid = v_o * h_avoid;
    lat_o_B = lat_o_A + (d_o_avoid * cosd(avoid_course)) / 60;
    lon_o_B = lon_o_A + (d_o_avoid * sind(avoid_course)) / (60 * cosd((lat_o_A + lat_o_B)/2));
    
    os_B = [lon_o_B, lat_o_B, v_o, return_course];
    ts_B = [lon_t_B, lat_t_B, v_t, c_t];

    % 3. 【新增】节点 C 推算 (复航结束 -> 回到原航线，恢复原航向 c_o)
    d_t_return = v_t * h_return;
    lat_t_C = lat_t_B + (d_t_return * cosd(c_t)) / 60;
    lon_t_C = lon_t_B + (d_t_return * sind(c_t)) / (60 * cosd((lat_t_B + lat_t_C)/2));
    
    d_o_return = v_o * h_return;
    lat_o_C = lat_o_B + (d_o_return * cosd(return_course)) / 60;
    lon_o_C = lon_o_B + (d_o_return * sind(return_course)) / (60 * cosd((lat_o_B + lat_o_C)/2));
    
    % 注意：在 C 点及以后，本船航向必须恢复为初始航向 c_o
    os_C = [lon_o_C, lat_o_C, v_o, c_o];
    ts_C = [lon_t_C, lat_t_C, v_t, c_t];

    %% --- 经济性指标 f1 ---
    f1 = t_straight + t_avoid + t_return;

    %% --- 安全性指标 f2 (评估三个关键节点的未来安全距离) ---
    [DCPA_A, TCPA_A, ~] = CPA(os_A, ts_A);
    [DCPA_B, TCPA_B, ~] = CPA(os_B, ts_B);
    [DCPA_C, TCPA_C, ~] = CPA(os_C, ts_C); % 【新增考核】
    
    % 远离判定处理
    if TCPA_A < 0; eff_A = 10; else; eff_A = abs(DCPA_A); end
    if TCPA_B < 0; eff_B = 10; else; eff_B = abs(DCPA_B); end
    if TCPA_C < 0; eff_C = 10; else; eff_C = abs(DCPA_C); end
    
    % 取整个生命周期中最危险（DCPA最小）的时刻作为整体安全指标
    min_actual_dcpa = min([eff_A, eff_B, eff_C]);
    
    % 取负号用于 gamultiobj 最小化优化
    f2 = - min_actual_dcpa;
    
    f = [f1; f2];
end