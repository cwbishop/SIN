%%%function y  = amp2db(x)
%%%Convert a change in amplitude to a change in dB

function y  = amp2db(x)
y = 20*log10(x);