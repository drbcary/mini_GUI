function [X,Y] = cumhist(data, xrange, delta)
% CUMHIST - Make data for a cumulative histogram plot
%
%   [X,Y]=CUMHIST(DATA,XRANGE,PERCENT_DELTA)
%
%    Generates X and Y variables suitable for plotting with
%    the plot function. Y values are generated for percentages
%    ranging from 0 to 100% in steps of PERCENT_DELTA. The XRANGE
%    for the plot is specified in XRANGE = [lowvalue highvalue].
%    
%    Example:
%
%      r=randn(1000,1); % 1000 normally-distributed random numbers
%      xrange = [-4 4];
%      percent_delta = 0.1; % use steps of 0.1%
%
%      [X,Y] = cumhist(r,xrange,percent_delta);
%      figure;
%      plot(X,Y,'k-');
%      hold on;
%      plot([-4 4],[50 50],'k--'); % add 'median' (50%-tile) dashed line
%      box off;
%      ylabel('Percentage');
%      xlabel('Values');
%
%    See also: PRCTILE, CUMSUM, HIST    
perc = prctile(data,0:delta:100);
[c index] = min(abs(perc'-xrange(2)));
max_perc = ((index+1)/(100/delta))*100;

if max_perc > 100 max_perc=100; end

Y = [0 0:delta:max_perc max_perc];
X = [xrange(1) prctile(data ,0:delta:max_perc) xrange(2)];
end
