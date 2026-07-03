function [dcpa, tcpa, d_current] = CPA(os, ts)
    % CALCULATE_CPA 计算本船与他船的最近会遇距离 (DCPA) 和最近会遇时间 (TCPA)
    % 
    % 输入参数:
    %   os - 本船状态向量 [经度(deg), 纬度(deg), 航速(kn), 航向(deg)]
    %   ts - 他船状态向量 [经度(deg), 纬度(deg), 航速(kn), 航向(deg)]
    %
    % 输出参数:
    %   dcpa      - 最近会遇距离 (单位: 海里/NM, 带符号, 绝对值越小碰撞危险越大)
    %   tcpa      - 最近会遇时间 (单位: 分钟/minutes, 负值表示已驶过最近会遇点)
    %   d_current - 两船当前实际距离 (单位: 海里/NM)

    % 1. 提取参数
    lon_o = os(1); lat_o = os(2); v_o = os(3); c_o = os(4);
    lon_t = ts(1); lat_t = ts(2); v_t = ts(3); c_t = ts(4);

    % 2. 坐标转换：将经纬度转换为局部平面直角坐标 (单位: 海里)
    % 采用局部平均纬度余弦投影，适合小范围避碰高精度解算
    lat_mean = (lat_o + lat_t) / 2;
    dx = (lon_t - lon_o) * 60 * cosd(lat_mean); % 东西向相对距离 (X轴)
    dy = (lat_t - lat_o) * 60;                  % 南北向相对距离 (Y轴)
    d_current = sqrt(dx^2 + dy^2);              % 计算当前两船实际距离

    % 3. 速度向量分解 (单位: 节, 即 海里/小时)
    % 航海中0度为正北，顺时针旋转。X轴对应东，Y轴对应北。
    v_ox = v_o * sind(c_o);
    v_oy = v_o * cosd(c_o);
    v_tx = v_t * sind(c_t);
    v_ty = v_t * cosd(c_t);

    % 4. 计算相对速度向量 (以本船为静止参考系)
    v_rx = v_tx - v_ox;
    v_ry = v_ty - v_oy;
    v_r_square = v_rx^2 + v_ry^2; % 相对速度的平方

    % 5. 求解 TCPA 和 DCPA
    if v_r_square < 1e-6
        % 如果相对速度极小 (两船同速同向平行航行)，则判定无会遇点
        tcpa = 0;
        dcpa = d_current;
    else
        % 计算 TCPA (公式计算结果为小时，乘以 60 转换为分钟)
        tcpa_hours = -(dx * v_rx + dy * v_ry) / v_r_square;
        tcpa = tcpa_hours * 60; 

        % 计算带符号的最近会遇距离 DCPA
        dcpa = (dx * v_ry - dy * v_rx) / sqrt(v_r_square);
    end
end