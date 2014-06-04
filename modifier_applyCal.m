function [Y, d]=modifier_applyCal(X, mod_code, varargin)
%% DESCRIPTION:
%
%   Function to apply filters estimated during calibration to stimuli prior
%   to playback. 