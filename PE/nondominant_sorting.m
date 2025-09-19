function [critic , actor] = nondominant_sorting(critic , actor , rule, critic_2, actor_2)

critic(rule).members = [critic(rule).members, critic_2];
actor(rule).members  = [actor(rule).members,   actor_2];

[critic(rule).pareto , R] = ND_opt (critic(rule).members);

if size(critic(rule).pareto, 1) > 20

    critic(rule).pareto = 