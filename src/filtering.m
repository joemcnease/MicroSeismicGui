function [ dat ] = filtering (data, fs, lowf, highf)
% This program is aimed to filter data using a 2nd order 2-pass butterworth
% filter. You can also use other filters by changing butter to others 

order = 2; % smaller order can handle much narrower freq band

nyq = fs/2;
[B,A] = butter(order,[lowf/nyq highf/nyq]);
dat = filtfilt(B,A,data);

end