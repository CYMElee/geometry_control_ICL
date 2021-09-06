clear;
close all;

addpath('geometry-toolbox')
%% set drone parameters
% simulation time
dt = 1/400;
sim_t = 10;

uav = drone_dynamic;
uav.dt = dt;            %delta t
uav.sim_t = sim_t;      %whole 
uav.t = 0:dt:sim_t;     %every time stamps

uav.d = 0.2;            %wing span
uav.m = 1.15;
uav.J = [0.0131, 0, 0;
         0, 0.0131, 0;
         0, 0, 0.0244];

uav.allocation_matrix = cal_allocation_matrix(uav.d, uav.c_tau);
uav.allocation_matrix_inv = cal_allocation_matrix_inv(uav.allocation_matrix);

%% create states array
uav.x = zeros(3, length(uav.t));
uav.v = zeros(3, length(uav.t));
uav.R = zeros(9, length(uav.t));
uav.W = zeros(3, length(uav.t));
uav.ex = zeros(3, length(uav.t));
uav.ev = zeros(3, length(uav.t));
uav.eR = zeros(3, length(uav.t));
uav.eW = zeros(3, length(uav.t));
uav.force_moment = zeros(4, length(uav.t));
uav.rotor_thrust = zeros(4, length(uav.t));

real_theta_array = zeros(3, length(uav.t));
theta_array = zeros(3, length(uav.t));

desired_x = zeros(3, length(uav.t));

%% initial state
uav.x(:, 1) = [0; 0; 0];
uav.v(:, 1) = [0; 0; 0];
uav.R(:, 1) = [1; 0; 0; 0; 1; 0; 0; 0; 1];
uav.W(:, 1) = [0; 0; 0];

%% create controller
control = controller;
integral_time = 0.05;
control.integral_times_discrete = integral_time/uav.dt;
disp(control.integral_times_discrete);
control.y = 0;
control.y_omega = zeros(3,1);
control.M_hat = zeros(3,1);

control.Y_array = zeros(1,control.integral_times_discrete);
control.Y_omega_array = zeros(3,control.integral_times_discrete);
control.M_array = zeros(3,control.integral_times_discrete);
control.W_array = zeros(3,control.integral_times_discrete);

control.sigma_M_hat_array = zeros(3,control.N);
control.sigma_y_omega_array = zeros(3,control.N);
control.sigma_y_array = zeros(control.N);

disp("integral times")
disp(control.integral_times_discrete)
%% create trajectory
traj_array = zeros(12, length(uav.t));
traj = trajectory;

%% create allocation matrix
       allocation_M = cal_allocation_matrix(uav.d,uav.c_tau);
       inv_allocation_M = inv(allocation_M);
       
%% create allocation matrix
        cos_45 = cosd(45);
%        real_allocation_M = [     1,     1,      1,     1;
%          -uav.d*cos_45, uav.d*cos_45, uav.d*cos_45, -uav.d*cos_45;
%           uav.d*cos_45 -0.05, uav.d*cos_45 -0.05,-uav.d*cos_45 +0.05, -uav.d*cos_45 +0.05;
%          -uav.c_tau, uav.c_tau, -uav.c_tau, uav.c_tau];
       uav.pc_2_mc = [0.05;0.01;0]; %pose center to mass center
       uav_l = uav.d*cos_45;
       pc_2_r = [  uav_l - uav.pc_2_mc(1),   uav_l - uav.pc_2_mc(1), -(uav_l + uav.pc_2_mc(1)), -(uav_l + uav.pc_2_mc(1));
                   uav_l - uav.pc_2_mc(2),-(uav_l + uav.pc_2_mc(2)), -(uav_l + uav.pc_2_mc(2)),     uav_l- uav.pc_2_mc(2);
                                        0,                        0,                         0,                        0;];
       disp(pc_2_r(:,1));
%% start iteration

traj_type = "position";   %"circle","position"
controller_type = "ICL";   %"origin","EMK","adaptive"

for i = 2:length(uav.t)
    t_now = uav.t(i);
    desired = traj.traj_generate(t_now,traj_type);
    desired_x(:,i) = desired(:,1);
    [control_output, uav.ex(:, i), uav.ev(:, i), uav.eR(:, i), uav.eW(:, i),control] = control.geometric_tracking_ctrl(i,uav,desired,controller_type);

    real_theta_array(:,i) = [uav.pc_2_mc(2),-uav.pc_2_mc(1),0];
    theta_array(:,i) = control.theta;
    
    rotor_force = allocation_M\ control_output;
    real_control_force = zeros(4,1);
    
    for rotor_num = 1:4
        real_control_force(1) = real_control_force(1)+rotor_force(rotor_num);
%         real_control_force(2:4) = real_control_force(2:4)+cross(pc_2_r(:,rotor_num),[0,0,-real_control_force(rotor_num)]);
        real_control_force(2:4) = real_control_force(2:4) + cross(pc_2_r(:,rotor_num),[0,0,-rotor_force(rotor_num)])';
    end
        real_control_force(4) = [-uav.c_tau, uav.c_tau, -uav.c_tau, uav.c_tau]*rotor_force;
%     disp("real control force:")
%     disp(real_control_force)
    
    X0 = [uav.x(:, i-1);
        uav.v(:, i-1);
        reshape(reshape(uav.R(:, i-1), 3, 3), 9, 1);
        uav.W(:, i-1)];
    [T, X_new] = ode45(@(t, x) uav.dynamics( x, real_control_force), [0, dt], X0);
    %disp( X_new(end, :))
    uav.x(:, i) = X_new(end, 1:3);
    uav.v(:, i) = X_new(end, 4:6);
    uav.R(:, i) = X_new(end, 7:15);
    uav.W(:, i) = X_new(end, 16:18);
    
%     disp("X:");
%     disp(uav.ex(:,i));
end

%% show the result
figure('Name','linear result');

subplot(3,2,1);
plot(uav.t(2:end),uav.x(1,2:end),uav.t(2:end),desired_x(1,2:end));
title('position x')
axis([-inf inf -2 2])
legend({'x','x_d'},'Location','southwest')
subplot(3,2,2);
plot(uav.t(2:end),uav.ex(1,2:end));
title('position error x')
axis([-inf inf -0.5 0.5])

subplot(3,2,3);
plot(uav.t(2:end),uav.x(2,2:end),uav.t(2:end),desired_x(2,2:end));
title('position y')
axis([-inf inf -2 2])
legend({'y','y_d'},'Location','southwest')
subplot(3,2,4);
plot(uav.t(2:end),uav.ex(2,2:end));
title('position error y')
axis([-inf inf -0.5 0.5])

subplot(3,2,5);
plot(uav.t(2:end),uav.x(3,2:end),uav.t(2:end),desired_x(3,2:end));
title('position z')
axis([-inf inf -2 2])
legend({'z','z_d'},'Location','southwest')
subplot(3,2,6);
plot(uav.t(2:end),uav.ex(3,2:end));
title('position error z')
axis([-inf inf -0.5 0.5])
%% rotation
figure('Name','rotation result');

subplot(3,1,1);
plot(uav.t(2:end),uav.eR(1,2:end));
title('eR x')
axis([-inf inf -0.1 0.1])
subplot(3,1,2);
plot(uav.t(2:end),uav.eR(2,2:end));
title('eR y')
axis([-inf inf -0.1 0.1])
subplot(3,1,3);
plot(uav.t(2:end),uav.eR(3,2:end));
title('eR z')
axis([-inf inf -0.1 0.1])

%% theta
figure('Name','theta result');

subplot(2,1,1);
plot(uav.t(2:end), theta_array(1,2:end),uav.t(2:end),real_theta_array(1,2:end));
legend({'theta1','theta1_d'},'Location','southwest')
title('theta 1')
subplot(2,1,2);
plot(uav.t(2:end), theta_array(2,2:end),uav.t(2:end),real_theta_array(2,2:end));
legend({'theta2','theta2_d'},'Location','southwest')
title('theta 2')
