function [Y, d] = modifier_instructions_by_trial(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Presents instructions using the "Instructions" GUI on a specific trial.
%   
% INPUT:
%
%   X:
%   
%   mod_code:
%
% Parameters:
%
%   'header':   string, header text for Instructions.fig. 
%
%   'body':     string, body text for Instructions.fig. This is basically
%               the instructions for the experimenter/listener.
%
%   'trial_number': which trial to present the instructions on. Note that 0
%                   will result in instructions being presented prior to
%                   experiment start. 