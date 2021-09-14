classdef trajectory
   methods
       function desired = traj_generate(obj, t,type)
        if type == "circle"
%            % xd, vd, b1d
           % xd
           desired_pose = zeros(3,1);
           desired_pose(1) = cos(1*t);
           desired_pose(2) = sin(1*t);
           desired_pose(3) = 1;
%            % vd
           desired_velocity = zeros(3,1);
           desired_velocity(1) = -sin(1*t);
           desired_velocity(2) = cos(1*t);
           desired_velocity(3) = 0;
%            % ad
           desired_acceleration = zeros(3,1);
           desired_acceleration(1) = -cos(1*t);
           desired_acceleration(2) = -sin(1*t);
           desired_acceleration(3) = 0;
%            % jd
           desired_jerk = zeros(3,1);
           desired_jerk(1) = sin(1*t);
           desired_jerk(2) = -cos(1*t);
           desired_jerk(3) = 0;
%            % sd
           desired_snap = zeros(3,1);
           desired_snap(1) = cos(1*t);
           desired_snap(2) = sin(1*t);
           desired_snap(3) = 0;
%            % b1d
            desired_b1 = [1;0;0];          
%            % b1d_dot
            desired_b1_dot = [0;0;0]; 
%            % b1d_ddot
            desired_b1_ddot = [0;0;0];          
%% fix pose
        elseif type == "position"
            desired_pose = zeros(3,1);
            desired_pose(1) = -0.5;
            desired_pose(2) = 0;
            desired_pose(3) = -1;
            desired_velocity = zeros(3,1);
            desired_velocity(1) = 0;
            desired_velocity(2) = 0;
            desired_velocity(3) = 0;
            desired_acceleration = zeros(3,1);
            desired_acceleration(1) = 0;
            desired_acceleration(2) = 0;
            desired_acceleration(3) = 0;
            desired_b1 = [1;0;0];
        end
%% return
            desired = [desired_pose,desired_velocity,desired_acceleration,desired_jerk,desired_snap,desired_b1,desired_b1_dot,desired_b1_ddot];
       end
   end
end