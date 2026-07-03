function action = case_encounter(os, ts, dcpa, tcpa)
    % case_encounter 判断碰撞危险、会遇局面并输出避让动作
    % 输入:
    %   os   - 本船状态 [经度, 纬度, 航速, 航向]
    %   ts   - 他船状态 [经度, 纬度, 航速, 航向]
    %   dcpa - 最近会遇距离 (海里, 带符号)
    %   tcpa - 最近会遇时间 (分钟)
    % 输出:
    %   action - 控制指令: 1(右转), -1(左转), 0(直行保向)

    % 1. 危险评估阶段
    safe_distance = 1.0; % 设定的安全会遇距离阈值：1海里
    
    % 如果两船正在相互远离(TCPA < 0)，或者DCPA绝对值满足安全距离，则无碰撞危险
    if tcpa < 0 || abs(dcpa) >= safe_distance
        action = 0; % 安全状态，直行保向
        return;
    end

    % --- 进入紧迫局面，开始责任划分与局面判定 ---
    
    % 2. 提取状态并计算相对几何关系
    lon_o = os(1); lat_o = os(2); v_o = os(3); c_o = os(4);
    lon_t = ts(1); lat_t = ts(2); v_t = ts(3); c_t = ts(4);

    % 计算目标船相对于本船的真方位 (True Bearing, 0~360度)
    lat_mean = (lat_o + lat_t) / 2;
    dx = (lon_t - lon_o) * 60 * cosd(lat_mean);
    dy = (lat_t - lat_o) * 60;
    
    % MATLAB中 atan2d(y,x) 是逆时针算，航海中 atan2d(x,y) 以正北为0顺时针算
    tb = mod(atan2d(dx, dy), 360);
    
    % 计算目标船的相对舷角 AOB (0~360度，0为正前方，90为右正横)
    aob = mod(tb - c_o, 360);
    
    % 计算两船航向交角 (C_diff)
    c_diff = abs(c_t - c_o);
    if c_diff > 180
        c_diff = 360 - c_diff; % 确保交角在 0~180 度之间
    end

    % 3. 核心 If-Else 逻辑树划分
    
    % (1) 对遇局面 (Head-on)
    % 目标船在正前方小范围内，且航向交角接近180度
    if (aob <= 5 || aob >= 355) && abs(180 - c_diff) <= 5
        action = 1; % 各自向右转，输出 1
        
    % (2) 他船追越本船 (Target overtaking own ship)
    % 目标船位于本船正横后大于22.5度 (即112.5 ~ 247.5度)
    elseif aob > 112.5 && aob <= 247.5
        action = 0; % 本船为被追越船/直航船，输出 0
        
    % (3) 本船追越他船 (Own ship overtaking target)
    % 本船速度更快，航向差较小，且目标船在本船正前方
    elseif v_o > v_t && c_diff <= 67.5 && (aob <= 5 || aob >= 355)
        % 利用带符号的 DCPA 判断目标船稍微偏左还是偏右
        if dcpa < 0
            action = -1; % 目标船偏左，本船向左转让清
        else
            action = 1;  % 目标船偏右，本船向右转让清
        end
        
    % (4) 右舷前部交叉相遇 (Crossing from starboard bow)
    % 目标船在右舷前部，本船为让路船
    elseif aob > 5 && aob <= 67.5
        action = 1; % 优先向右转从他船尾部穿过，输出 1
        
    % (5) 右舷后部交叉相遇 (Crossing from starboard quarter)
    % 目标船在右舷后部
    elseif aob > 67.5 && aob <= 112.5
        action = -1; % 若右转会顺着来船航向，故规定向左转绕清，输出 -1
        
    % (6) 左舷交叉相遇 (Crossing from port)
    % 目标船在左舷，本船为直航船
    elseif aob > 247.5 && aob < 355
        action = 0; % 本船直行保向，让对方避让，输出 0
        
    % 其他情况
    else
        action = 0;
    end
end