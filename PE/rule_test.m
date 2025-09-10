clear; clc

%%

load("policy")
angle=10;

close all

figure

for i = 1:size(critic(51).members,1)

    plot(critic(51).members(i,1),critic(51).members(i,2),'*r')
    hold on

    text(critic(51).members(i,1),critic(51).members(i,2),sprintf("\\leftarrow angle: %.2f",critic(51).index(i)))

end

x_l    = zeros(2,1);
x_l(1) = critic(rule).minimum_members(1);
x_l(2) = 1;

y_l    = zeros(2,1);
y_l(1) = critic(rule).minimum_members(2);
y_l(2) = critic(rule).minimum_members(2) + tan(angle_list(angle))*(1 - critic(rule).minimum_members(1));

plot(x_l,y_l,'--k')
% axis("square")
title(sprintf("angle: %.2f",angle))