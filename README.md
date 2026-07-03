# 无人船避碰系统

本项目意图利用GA规划无人船舶避碰路线，目前初步实现GA单目标优化、CPA计算、会遇局面判断，以及编码避撞航线多目标的帕累托优化，下一步实现航线可视化。

## 文件说明

- src
  - [main.m](./src/main.m)  
    *主程序*
  - [CPA.m](./src/CPA.m)  
    *CPA计算函数，输入四维AIS数据，输出DCPA和TCPA*  
  - [case_encounter.m](./src/case_encounter.m)  
    *危险&会遇局面判断函数，输入四维AIS、DCPA、TCPA，输出行动编号（-1，0，1）*  
  - [fitness.m](./src/fitness.m)  
    *适应度函数计算*  


- test  
  - [GA_singletarget.m](./src/GA_singletarget.m)   
    *输入任意维自变量，给定取值范围和适应度函数，输出优化结果和收敛曲线*  
  - [test_CPA_encounter.m](./test/test_CPA_encounter.m)  
    *测试CPA和会遇局面判断函数，可设定AIS数据，展示计算结果*  


- result  
  - [result_singletarget.png](./result/result_singletarget.png)  
    *GA_singletarget.m 运行收敛曲线*  
  - [result_Pareto.png](./result/result_Pareto.png)
    *main.m 运行帕累托前沿*

