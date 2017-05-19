classdef ScannerCore
%ScannerCore Provides the calculation routines for the PupilFill class
%
% See also PUPILFILL, HEIGHTSENSORCORE
    
% Some of the methods in this class are from legacy code from the old
% PupilFill controller and do not use Hungarian notation like the rest
% of the code base. At some point I may convert them.  In the interest
% of spending my time on developing new stuff, I'm going to leave them
% as is for now. - CNA
    
    
    properties (Constant)
    end
    
    methods (Static)      
        
        function [vx, vy, vx_gc, vy_gc, t, f_min, f_max] = getMulti( ...
                pole_num, ...
                sig_min, ...
                sig_max, ...
                circle_num, ...
                circle_dwell, ...
                circle_ramp_time_frac, ...
                offset, ...
                rot_angle, ...
                x_offset_global, ...
                y_offset_global, ...
                Hz, ...
                volts_scale, ...
                dt, ...                 % us
                filter_width, ...       % Hz
                full_fill_period, ...   % s
                use_period ... 
                )

            fill_num = 1;
            
            % 2009.05.20 CNA
            % In one of the old versions of this stuff you have a
            % getMultipoleWaveformC_visual that shows plots at each step of
            % the way. One of these days you should probably write a LaTeX
            % document about how all of this works.

            % 2007.04.04 CNA
            % The filtering I'm doing on the waveforms seems to be fucking
            % some stuff up.  Namely, it's changing the sigma of the pole.
            % I've found a way to correct the sigma of the poles by
            % changing vx_scale and vy_scale by a correction factor, so we
            % must also compensate for this correction in offset (which,
            % unaffected by filtering, would be too large by the
            % compensation factor) by pre-adjusting the offset by the
            % inverse of the correction factor

            % UPDATE 2008.04.04 I will comment out the offset adjustment here.

            % if circle_num == 1;
            %     offset = offset/1.11;
            % else
            %     offset = offset/1.09;
            % end

            % Naulleau scale factor
            % offset = offset/1.2;

            % END UPDATES

            % When circle_num == 1, default the sig value of the pole to
            % the sig_max. One problem arises however when we calculate the
            % extra time needed to carve alignment phase because it will
            % use the value sig_min if it exists so when circle_num == 1,
            % we set sig_min == sig_max

            if circle_num == 1;
                sig_min = sig_max;
            end

            r_values = linspace(sig_min,sig_max,circle_num); % radii of one pole
            
            % Update 2013.06.14
            % Add support for "period solve" mode where instead of telling
            % it an average frequency of operation, we tell it the period
            % of the full scan. 
            
            if use_period
                
                % Overwrite frequenzy to achieve approximate period we
                % want.  
                
                % Step 1: How many circles do we need to do?
                
                full_fill_circles = circle_dwell*circle_num*pole_num;
                
                % Add 1 circle for the sum of all pole alignment
                
                full_fill_circles = full_fill_circles + 1;
                
                
                % The back of the envelope calculation for frequency is:
                % Hz = full_fill_circles/full_fill_period.  
                
                % But we can be smart and compensate for extra time added
                % by pole transitions.
                
                % Since I do pole transition time as a fraction of the full
                % fill period, this is really easy.
                
                % When circle_ramp_time_frac = 1, half of the time is spent
                % ramping, half carving circles.  
                
                % full_fill_with_ramps = full_fill_time(1 + circle_ramp_time_frac);
                
                % We want to compensate full_fill_time so that full_fill_time with_ramps = full_fill_time
                                
                full_fill_period_comp = full_fill_period/(1 + circle_ramp_time_frac);
                
                Hz = full_fill_circles/full_fill_period_comp;
                
            end
            
            % 2013.06.14 (end updates) At this point, proceed as if we want
            % to keep frequency fixed at Hz...
                
            % Assume that the frequency stays fixed at all radii
            % (eventually the freq will change to keep velocity fixed, but
            % for now go with this assumption).  How long does it take to
            % fill carve out one pole?
            
            % Example: if you have 3 circles per pole and a dwell of 2 that
            % is 6 circles/pole.  Carving out Hz circles/second gives  6/Hz
            % seconds/pole or:
           
            pole_time = circle_dwell*circle_num/Hz;
            
            % But what we really want is to have the velocity of the beam
            % stay constant as we fill the pupil (so intentisy is uniform
            % at each fill position).  The total distance traveled in
            % filling one pole is given by sum(2*pi*r*dwell) where r is the
            % vector of radii in the pole. 
            
            pole_dist_traveled = sum(2*pi*r_values*circle_dwell);
            v = pole_dist_traveled/pole_time;

            % Define T as a vector that is the time spent at each radius. T
            % is a vector of size(r_values).  Note that we multiplied by
            % dwell.

            T = 2*pi*r_values*circle_dwell/v;
            
            
            % Update 2012.06.14
            % Need to calculate Hz that the total fill has a period of 
            % full_fill_period
            
            
%             if use_period
%             
%                 if floor(pole_num/2) == pole_num/2 
% 
%                     % even number of poles, one "full fill" of the waveform will contain 
%                     % an integer number of periods
% 
%                     period_num = pole_num/2; 
%                     raw_full_fill_period = max(Tsum)*period_num;
%                     scale_factor = full_fill_period/raw_full_fill_period;
%                     Tsum = Tsum*scale_factor;
% 
%                 else
% 
%                     % odd number of poles
% 
%                     if(pole_num == 1)
% 
%                         % The "full fill" waveform will be ~ 1/2 of a period
%                         % but half of the time it does the out-to-in and half
%                         % of the time it does in-to-out pole so you want
%                         % max(Tsum) to be 2*full_fill_period
% 
%                         period_period = 2*full_fill_period;
%                         Tsum = Tsum*(period_period/max(Tsum));
%                     else
% 
%                         % The "full fill" waveform will contain an integer
%                         % number of periods and one half period that is an
%                         % in-to-out circle
% 
%                         full_periods = floor(poles_total/2);
%                         raw_full_fill_period = max(Tsum)*full_periods + Tsum(circle_num+1);
%                         scale_factor = full_fill_period/raw_full_fill_period;
%                         Tsum = Tsum*scale_factor;
% 
%                     end
% 
%                 end
%                 
%             end
            
            % Now lets think about transitioning between poles and doing
            % that in a fluid way for the scanners.  Consider dipole where
            % each pole has two circles.  The first circle will be drawn
            % inner radius, then outer radius then from the outer radius of
            % the first pole, you transition to the outer radius of the
            % second pole, then draw the inner radius of the second pole,
            % then from the inner radius of the second pole you transition
            % to the inner radius of the first pole.  This repeats
            % indefinitely
            
            % The idea of "pole transition alignment" is that you need to
            % carve out an extra distance of 1/pole_num*circumference so
            % that you leave and enter each pole tangentially.
            
            % When the pole is drawn in-to-out (poles 1, 3, 5, ...), the
            % transition alignment always occurs on the sig_max of the pole
            
            % When the pole is drawn out-to-in (poles 2, 4, 6, ...), the
            % transition alignment occurs on the sig_min of the pole
            
            % Since we keep velocity constant, the time required to carve out
            % the transition alignment phase is different for in-to-out vs.
            % out-to-in poles.
            
            % Circumference of outer circle of pole == 2*pi*sig_max
            % Circumference of inner circle of pole == 2*pi*sig_min
            
            % Divide circumference by number of poles to get the extra path
            % around the pole that we should travel during "pole
            % alignment".
            
            % Divide the extra path by the velocity to get the extra time
            % we need to spend on the outer pole and inner poles

            t_outer = 2*pi*sig_max/pole_num/v;
            t_inner = 2*pi*sig_min/pole_num/v;
            
            % The in-to-out -> out-to-in -> in-to-out -> ... repeats
            % indefinitely and we can develop the notion of a 'period' for
            % this pupil fill.  Because the pole transition alignment phase
            % alternates between the outer circle and inner circle every
            % other pole, the behavior of the phase w(t)*t should be
            % identical every 'period', that is the time to fill two poles
            % including the pole transition alignment time on the outer
            % circle from the first  pole and the pole transition alignment
            % time on the inner circle from the second pole.  The next two
            % poles that get carved out should a phase that changes in time
            % the exact same way, it will just start at a different value
            % corresponding to the phase that the beam enters the third
            % pole.
            
            % half-fill time, w(t)*t product at half fill

            % Construct vector of times at each radius during one period

            T = [T fliplr(T)];
            r_values = [r_values fliplr(r_values)];

            Textra(circle_num) = t_outer;
            Textra(2*circle_num) = t_inner;

            Ttotal = T + Textra;

            % Tsum(n) is the amount of time that has gone by to get to the 
            % beginning of circle(n) in the full period fill 

            Tsum = zeros(1,length(Ttotal));

            for n = 1:length(Ttotal);
                Tsum(n+1) = sum(Ttotal(1:n));
            end
            
            % Update 2012.06.14 
            % sum(T) + t_outer is the time to do one in-to-out pole
            % sum(T) + t_inner is the time to do one out-to-in pole
            
            t_in2out = sum(T) + t_outer;
            t_out2in = sum(T) + t_inner;
            
            % There are ceil(pole_num/2) in-to-out poles in the fill and
            % floor(pole_num/2) out-to-in poles in the fill
            
            T_full_fill = ceil(pole_num)*t_in2out + floor(pole_num/2)*t_out2in;
           
            % Since Tsum(n) is the amount of time that has gone by to get
            % to the beginning of circle(n) in the full period fill,
            % Tsum(1) is 0 and Tsum(circle_num + 1) is the time it takes to
            % just finish the first pole including the pole transition
            % alignment time. It is at this point we should start time
            % flipping back around. The problem is that the time to fill
            % the second pole including pole transition alignement time
            % will be less than the time for the first pole.  This is
            % because the alignment phase is carved on circles of different
            % radius in the forward and backward fill directions. -- We
            % will not be able to go all the way back to 0 with the time
            % vector

            % The pseudo-saw time vector should be periodic in two poles
            % because we alternate inner and outer transition alignment
            % times every two poles

            % Construct saw vector in normal way, except we make the
            % turnaround point the time it takes to fill the first pole and
            % complete it's pole alignment phase.

            % UPDATE 2008.04.03 Figured out problem with little blips
            % (small points) on some of the waveforms.  I was adding one
            % extra element in my time vector in some instances and this
            % caused the phase-jump part of the rourine to want to put an
            % alignment phase at this extra time element and so it doubled
            % the alignment phase time at this point.

            % UPDATE 2009.05.21 Was still having problems with a few
            % waveforms.  I ended up fixing this by changing samples =
            % floor(samples) to samples = round(samples).  And somehow this
            % worked.  I don't get it.

            samples = max(Tsum)/dt;
            samples = round(samples);
            dt = max(Tsum)/samples;

            T_half = Tsum(circle_num+1); % includes the pole transition alignment time
            
            % The angular frequency at the exit of the first pole is the
            % velocity divided by the radius or v/max(r_values).  Thus the
            % product of w*t is:
            
            wt_half = v/max(r_values)*T_half;

            t = 0:dt:max(Tsum)-dt;
            tsaw = ScannerCore.saw(t,T_half); % tsaw will not go all the way back to zero 

            % figure
            % plot(t,tsaw)

            % Generate phase values for one period

            r = zeros(size(t));
            w = zeros(size(t));
            wt = zeros(size(t));
            wt_saw = zeros(size(t));

            r(1) = r_values(1);
            w(1) = v/r(1);

            % Set up to correct the phase after the turnaround point.  To see more
            % details of how this is done, look at saw.m - I do it here the exact same
            % way it is done there.  These will be used in the loop below
            
            % For each time sample, figure out the value of:
            % r (radius)
            % wt_saw (at that time)
            % w (angular frequency at that time)
            % wt (at that time)

            c = floor(t/T_half);
            d = floor((c+1)/2);

            for m = 1:length(Tsum)-1;
                for n = 1:length(t);

                    if t(n) <= Tsum(m+1) && t(n) > Tsum(m)

                        r(n) = r_values(m);
                        wt_saw(n) = tsaw(n)*v/r(n);
                        w(n) = v/r(n); % instantaneous frequency at each time sample
                        wt(n) = (-1)^c(n)*wt_saw(n) + 2*d(n)*wt_half;

                    end 
                end
            end
            
            f_max = round(max(w)/2/pi);
            f_min = round(min(w)/2/pi);

            % figure
            % plot(t,w/2/pi)

            % figure
            % plot(t,r,'.r')
            % xlabel('t')
            % ylabel('r')
            % figure
            % plot(t,wt_saw,'.r',t,wt,'.b')
            % legend('wt saw', 'wt corrected')
            % title('Phase of one full period (two poles)')
            % xlabel('t')
            % ylabel('wt saw')

            % Get the half period (pole with outer circle alignment) wt and r vectors

            N_half_period = length(find(t <= Tsum(circle_num + 1)));
            wt_half_period = wt(1:N_half_period);
            r_half_period = r(1:N_half_period);
            t_half_period = t(1:N_half_period);

            % figure
            % plot(t_half_period,wt_half_period,'.r')
            % title('Half period phase (wt) values')


            % Now repeat the r and wt vectors enough times to cover the full range of t.  
            % There are pole_num*fill_num poles total.  If this
            % is an even number, we will have an integer number of 'periods'.  If this
            % is an odd number, we will have some number of periods and a half period.

            % WHAT ABOUT DWELL: It doesn' matter.  Say dwell = 2 and circ_num = 3 then
            % it would do 2 circles on small circle, 2 circles on middle, and 2 on the
            % outside and this would be ONE POLE!

            % When we're monopole, we must fill from in-to-out, then come back out-to-
            % in so we start and stop at the same point.  If we set fill_num to 1, we
            % need to make the time vector long enough to do a two poles, the first an 
            % in to out and the second an out to in, the only differences is that there
            % is no physical translation between the in to out and out to in poles.

            if pole_num == 1
                poles_total = pole_num*fill_num*2;
            else
                poles_total = pole_num*fill_num;
            end

            if pole_num == 1
                phase_increment = pi;
            else
                phase_increment = 2*pi/pole_num;
            end
            start_phase = -pi/pole_num + rot_angle*pi/180;
            inc_per_pole = circle_num*circle_dwell*pole_num + 1;
            phase_count = floor(wt./phase_increment);
            pole_count = floor(phase_count/inc_per_pole)+1;


            % ----------------------------------------------------------------
            % Precompensate for gain losses due to smoothing filter.  
            % ----------------------------------------------------------------

            % Here is the snipet of code I use for filtering:

            % if pole_count == 1;
            %     filt = rect(freq,2*filter_width);
            % else
            %     filt = exp(-(freq/filter_width).^4/2); 
            %     % filt = gauss(freq,filter_width);
            % end

            % Get amplitude of smoothing filter at each time value 

            if pole_count == 1;
                filt_amp = rect(w/2/pi,2*filter_width);
            else
                filt_amp = exp(-(w/2/pi/filter_width).^4/2); 
                % filt = gauss(freq,filter_width);
            end

            r = r./filt_amp;

            % ----------------------------------------------------------------------
            % Introduce GAIN compensation vs. Hz due to scanner nonlinearities TRY 1
            % ----------------------------------------------------------------------

            % OK, at this stage I am ready to compensate for frequency dependent gain.
            % we will call the nominal frequency = 200 so that we normalize the gains
            % in the experimental data (plotted in gain_data.m) to the gain at 200 Hz.
            % Then we will use the linear formula to compute the relative gain of the
            % other frequencies w.r.t. to the gain at 200 Hz.

            % 2007.09.10 Gain measured from scope NOT PUPIL:

            % gain = 1.2169 - .0010745*w/2/pi;

            % UPDATE: 2007.10.01 gain measured at pupil:

            % gain = 1.97 - .0038*w/2/pi;
            % gain = 1.8566 - .003333*w/2/pi;
            % gain = 1.7453 - .0029*w/2/pi;
            % gain = 1.645 - .0025*w/2/pi;
            % gain = 1.59 - .0023*w/2/pi;

            % ----------------------------------------------------------------------
            % Introduce GAIN compensation vs. Hz due to scanner nonlinearities TRY 2
            % ----------------------------------------------------------------------

            % UPDATE: 2008.04.09 we have made new gain measurements from the AWG to the
            % pupil.  We have determined that changing the voltage at the AWG by a
            % factor changes the sigma by the same factor at all frequencies.  This is
            % great because it let's use one frequency gain curve to compensate and we
            % don't need a 2D parameter space.  

            % OK, say we know that at 300 Hz with asignal swinging between plus/minus
            % 2.25 volts that we get sig = .4  If we desire sig = .5 at 300 Hz 
            % all we need to do is scale the voltage range of plus/minus 2.25 volts
            % by .5/.4 to 1.25*2.5 and we will get the correct sigma at 300 Hz.  

            % Ok, so what is the gain_compensation_factor?  Volts programmed 
            % = 5*sig_desired; Volts_programmed*gain_compensation_factor = Volts_needed 

            % gain_compensation_factor: 

            % 2.25*(sig_desired/sig_at_2.25_and_freq)/(5*sig_desired) = 
            % (2.25/5)/sig_at_2.25_and_freq.

            % MEASURED GAINS FROM AWG TO PUPIL 2008.04.09.  We used a sine wave with
            % Vpp = 4.52 which means it swang between plus/minus 2.26 volts

            % sig_at_2.26_volts(Hz) = slope*Hz + icept
            % slope = -0.00058147275655   
            % icept = 0.63461062906837 

            % Get gain correction as a funciton of w(t).  I.E., w is the 
            % instantaneous frequency at the current time so we can get gain as a
            % function of time based on the frequency we are at.  We also have r as a
            % function of time so just multiply the gain_correction vector with the r
            % vector and you're done.

            sig_at_2point26_volts = -.0005814*w/2/pi + .6346;
            gain_correction = (2.26/5)./sig_at_2point26_volts;

            % figure
            % plot(gain_correction,'.-')
            % prettyWG

            r_gc = r.*gain_correction; 
            r_half_period_gc = r_gc(1:N_half_period);

            % ----------------------------------------------------------------------
            % Extend the r, and wt vectors to fill all of the poles, pole_num's ect.
            % ----------------------------------------------------------------------

            tempwt = wt;
            tempr = r;
            tempr_gc = r_gc;

            
            
            if floor(poles_total/2) == poles_total/2 % even

                period_num = poles_total/2;

                for n = 1:period_num - 1
                    wt = [wt (tempwt+max(wt))];
                    r = [r tempr];
                    r_gc = [r_gc tempr_gc];
                end

            else % odd 

                period_num = (poles_total - 1)/2;

                for n = 1:period_num - 1
                    wt = [wt (tempwt+max(wt))];
                    r = [r tempr];
                    r_gc = [r_gc tempr_gc];
                end

                % Because we have the half period at the end..
                wt = [wt (wt_half_period+max(wt))];
                r = [r r_half_period];
                r_gc = [r_gc r_half_period_gc];


            end

            % figure
            % plot(t,r_gc,'r',t,r,'b')
            % legend('gain corrected','desired')

            N = length(wt);
            t = 0:dt:(N-1)*dt;

            % figure
            % plot(t,r,'.r')
            % figure
            % plot(t,wt,'.r')
            % title('Phase of entire fill')

            % Correct the jumps in the w(t)*t product.  I.E., when the instantaneous
            % frequency instantaneously jumps, the w(t)*t product jumps.  The problem 
            % is that when we do this, we create two time points with the same 
            % phase whenever we have a radius jump.  This is bad!!  
            % Need to figure this out. OOOH, I think I've got it.  
            % We need to add the phase separation between samples on the
            % circle we're switching to.

            wt_jump = 0;
            count = 0;

            % 2008.04.03 Even though we've added gain compensation on r, we do not need
            % to concern ourselves with it here b/c the jumps in r will still be at the
            % same times.  

            for n = 1:length(t)

                % Find when rsaw changes; these are the phase jump indicators

                    if n > 1
                        if (r(n) - r(n-1)) ~=0 % we jump to next radius
                            count = count + 1;
                            wt_sample_spacing = wt(n+2) - wt(n+1);
                            wt_jump = wt(n) - wt(n-1) - wt_sample_spacing;
                        end
                    end

                  wt(n) = wt(n) - wt_jump; 

            end

            % figure
            % plot(t,wt,'.r')
            % title('Remove jumps from wt corrected')

            % vx = r.*cos(wt);
            % vy = r.*sin(wt);
            % vx_gc = r_gc.*cos(wt);
            % vy_gc = r_gc.*sin(wt);

            % figure
            % plot(vx,vy)


            % % Add small phase between circles of different radii
            % 
            % count = 0;
            % step_jump = 2*pi*step_jump_frac;
            % 
            % for n = 1:length(t)
            %     
            %         if n > 1
            %             if (rsaw(n) - rsaw(n-1)) ~=0 % we jump to next radius
            %                 count = count + 1;
            %             end
            %         end
            %         
            %     wt(n) = wt(n) + count*step_jump;
            % end
            % 


            % -------------------------------------------------------
            % Get the x and y offsets of the different pole positions
            % -------------------------------------------------------

            xc = zeros(1,pole_num);
            yc = zeros(1,pole_num);
            xc_gc = zeros(1,pole_num);
            yc_gc = zeros(1,pole_num);

            for n = 0:pole_num-1

                % UPDATES 4/4/2007 with Naulleau.  We want to add different
                % individual offsets corrections in x and y in monopole and multipole modes.
                % to compensate for weird asymmetric problems in Paul's gain feedback
                % loop

                mono_x = 1;
                mono_y = 1;
                multi_x = 1;
                multi_y = 1;

                if pole_num == 1

                    xc(n+1) = offset*cos((rot_angle+n*(360/pole_num))*pi/180);
                    xc_gc(n+1) = xc(n+1)*mono_x;
                    yc(n+1) = offset*sin((rot_angle+n*(360/pole_num))*pi/180);
                    yc_gc(n+1) = yc(n+1)*mono_y;

                else

                    xc(n+1) = offset*cos((rot_angle+n*(360/pole_num))*pi/180);
                    xc_gc(n+1) = xc(n+1)*multi_x;
                    yc(n+1) = offset*sin((rot_angle+n*(360/pole_num))*pi/180);
                    yc_gc(n+1) = yc(n+1)*multi_y;
                end

                % --------- END UPDATES

            end

            % Keep track of how many phase increments have been carved out.  OK, what
            % the fuck does 'phase increament' mean?  Because we have these 'alignment
            % phase' when we transition from pole to pole in multipole fills the
            % natural 'phase increment' of the system is 2pi/pole_num.  I.E, when we
            % have 3 poles, the 'alignment' phase is 1/3 of a circle.  3 of these gets
            % you 3 transitions and back to where you want to be after three poles.

            % This enables one to keep track of the current pole number.  Generate pole
            % number, fullfill count and periodic pole number vectors.

            if pole_num == 1
                phase_increment = pi;
            else
                phase_increment = 2*pi/pole_num;
            end
            
            start_phase = -pi/pole_num + rot_angle*pi/180;
            inc_per_pole = circle_num*circle_dwell*pole_num + 1; % the + 1 is for the transition.
            phase_count = floor(wt./phase_increment);
            pole_count = floor(phase_count/inc_per_pole)+1;
            full_count = floor((pole_count-1)/pole_num)+1;
            periodic_pole_count = pole_count - (full_count -1)*pole_num;

            % figure
            % plot(t,phase_count,'.r',t,pole_count,'.b');
            % title('number of phase increments') 
            % legend('num of phase increments','current pole')
            % xlabel('time (sec)')
            % 
            % figure
            % plot(t,full_count,'.r',t,periodic_pole_count,'.b')
            % legend('full full count','periodic pole count')

            % Create waveforms

            % ------ MODS 4/4/2007:  The filtering process causes the amplitudes of the
            % waveforms to decreace slightly so I will 'pre-correct' for this with a
            % correction factor that is tested by generating say .4 annular waveforms
            % and looking at the exported config file to see if the voltage truly
            % swings between -2 and +2 V for a 4Vpp signal.  Tested with filter = 450
            % Hz

            % I used to have a huge for loop here (which makes it more obvious what
            % it is doing but I realized I don't need it and it is faster w/o it.

            vx = volts_scale*(r.*cos(wt+ start_phase) + xc(periodic_pole_count));
            vy = volts_scale*(r.*sin(wt+ start_phase) + yc(periodic_pole_count));
            vx_gc = volts_scale*(r_gc.*cos(wt+ start_phase) + xc_gc(periodic_pole_count));
            vy_gc = volts_scale*(r_gc.*sin(wt+ start_phase) + yc_gc(periodic_pole_count));

            % figure
            % plot(t,vx,'r',t,vy,'b',t,vx_gc,'g',t,vy_gc,'y')
            % title('Signals w/o ramps')
            % legend('vx','vy','vx gc','vy gc')

            % Add RAMPS between poles if pole_num ~= 1

            % circshift signals before we put into ramp loop so that we get a ramp at
            % the endpoints. Be really careful about transposing vectors. Keep
            % everything in row vectors at all times!!!

            shift_num = 50;
            pole_count = circshift(pole_count',shift_num)';
            vx = circshift(vx',shift_num)';
            vy = circshift(vy',shift_num)';
            vx_gc = circshift(vx_gc',shift_num)';
            vy_gc = circshift(vy_gc',shift_num)';

            if pole_num ~= 1 

                T_move = circle_ramp_time_frac*T_half;   % this is a fraction of the fundamental period
                                                    % user enters circle_ramp_time_frac in GUI.
                sm = floor(T_move/dt); %samples


                % Predefine the ramp vectors before the loop so they don't grow through
                % the loop and slow down the code

                vx_ramp = zeros(1,length(vx)+ max(pole_count)*sm);
                vy_ramp = zeros(1,length(vx)+ max(pole_count)*sm);
                vx_gc_ramp = zeros(1,length(vx)+ max(pole_count)*sm);
                vy_gc_ramp = zeros(1,length(vx)+ max(pole_count)*sm);

                count = 0;
                for n = 1:length(t)

                net_shift = count*sm;

                % Find when pole_count changes; these are ramp location indicators
                % At these locaions, we fill the dicontinuity with a linear ramp
                % between the start and end values of the signal.  The number of
                % samples that each ramp takes is given by sm, the samples in the move.

                    if n > 1
                        if abs(pole_count(n) - pole_count(n-1)) ~= 0;
                            vx_ramp(n + net_shift:n + net_shift + sm -1)...
                                = linspace(vx(n-1),vx(n),sm);
                            vy_ramp(n + net_shift:n + net_shift + sm-1)...
                                = linspace(vy(n-1),vy(n),sm);
                            vx_gc_ramp(n + net_shift:n + net_shift + sm -1)...
                                = linspace(vx_gc(n-1),vx_gc(n),sm);
                            vy_gc_ramp(n + net_shift:n + net_shift + sm-1)...
                                = linspace(vy_gc(n-1),vy_gc(n),sm);

                            count = count + 1;
                            net_shift = count*sm;
                        end
                    end


                % So, if there was a discontinuity from this time step to the next one,
                % we just added a nice linear ramp down (or up to) the current signal
                % value and we can start filling in again until the next discontinuity

                % Here we're just filling in the normal values 

                    vx_ramp(n + net_shift) = vx(n);
                    vy_ramp(n + net_shift) = vy(n);
                    vx_gc_ramp(n + net_shift) = vx_gc(n);
                    vy_gc_ramp(n + net_shift) = vy_gc(n);

                end

                t = 0:dt:(length(vx_ramp)-1)*dt;
                vx = vx_ramp;
                vy = vy_ramp;
                vx_gc = vx_gc_ramp;
                vy_gc = vy_gc_ramp;

            end

            % figure
            % plot(t,vx,'r',t,vy,'b',t,vx_gc,'g',t,vy_gc,'y')
            % title('Signals with ramps')
            % legend('vx','vy','vx gc','vy gc')

            vx = circshift(vx',-shift_num)';
            vy = circshift(vy',-shift_num)';
            vx_gc = circshift(vx_gc',-shift_num)';
            vy_gc = circshift(vy_gc',-shift_num)';

            % figure
            % plot(t,vx,'r',t,vy,'b')
            % title('signals with ramps')


            %=======================================================================

            % Compute FT and filter.  First, we'll wrap the ends so that we can make
            % this beast not have a discontinuity at the endpoints!

            vx = ScannerCore.lowpass(vx, t, filter_width);
            vy = ScannerCore.lowpass(vy, t, filter_width);
            
            % Add offset
            vx = vx + x_offset_global*volts_scale;
            vy = vy + y_offset_global*volts_scale;
            vx_gc = vx_gc + x_offset_global*volts_scale;
            vy_gc = vy_gc + y_offset_global*volts_scale;
            

            % figure
            % plot(t,vx,'r',t,vy,'b',t,vx_gc,'g',t,vy_gc,'y')
            % title('Signals with ramps and filtered')
            % legend('vx','vy','vx gc','vy gc')
            
        end
        
        


        function out = saw(t,T)
            
            % saw: generates a saw wave with peaks at 0 and 1, period T

                    
            dt = t(2)-t(1);
            if 2*dt > T
                error('ERROR: need larger period (T) or better signal sampling')
                pause;
            end

            % % Pre-build vector before for loop
            % out = zeros(size(t));
            % 
            % for n =  1:length(t)
            %     
            %     c = floor(t(n)/T);
            %     out(n) = (-1)^c*t(n) + (-1)^(c+1)*2*floor((c+1)/2)*T;
            %              % slope     +   % y - intercept goes like +2*T,
            %              % -2*T, 4*T,-4*T
            % end

            % MODS 2009.05.21:  I realized we can create the saw a lot more
            % efficiently with the following code.  The old stuff is above
            % and is commented out.

            c = floor(t/T);
            d = floor((c+1)/2);
            out = (-1).^c.*t + (-1).^(c+1)*2.*d*T;
        
        end
        
        function [u] = space2freq(x)

            dx = x(2) - x(1);
            L = max(x) - min(x);
            N = length(x);

            u = -1/2/dx: 1/dx/N : 1/2/dx - 1/dx/N;
        end
        
        
        function [vx, vy, vx_gc, vy_gc, t] = getDC(dc_xoffset, dc_yoffset, volts_scale, dt)

            dc_time = 5*10^-3; % Always make the time 5 ms.

            t = 0:dt:dc_time;
            samples = length(t);

            vx = ones(1,samples)*volts_scale*dc_xoffset;
            vy = ones(1,samples)*volts_scale*dc_yoffset;
            vx_gc = vx;
            vy_gc = vy;
            
        end
        
        
        
        function [coordX, coordY, coordT] = getRastorString(stringCoords)

            % Kurt Schlueter, 2013
            
            % Ok the goal here is to take in a string of coordinates
            % (x,y,t) and turn them into usable numeric coordinates that we
            % can plot and analyze. validateInput uses this and
            % getRastorWaveform uses this.

            % Ok the goal here is to take in a string of coordinates (x,y,t) and turn them into
            % usable numeric coordinates that we can plot and analyze. 

            lengthString = length(stringCoords);

            miniCoordStep = 1;
            coordStep = 1;

            coordX = [];
            coordY = [];
            coordT = [];

            usedX = 0; %x most recently used
            usedY = 0; %y most recently used
            usedT = 1; %t most recently used

            for k = 2:1:lengthString;  % This will go through every character in the string
                %k

                if lengthString ~= k

                    if stringCoords(k - 1) == '(' && usedT == 1 %if the character before is a starting parenthesis then we know a numeric value is starting (X value)

                        %the trick here is that the coordinates can be different lenghts,
                        %decimals and negatives so how do we capture all of that to produce
                        %a specific coordinate

                        coordXx = stringCoords(k);
                        %miniCoordStep

                        while stringCoords(k + miniCoordStep) ~= ','  %This will work here because it is after the beginning character

                            coordXx = [coordXx, stringCoords(k + miniCoordStep)]; % we need to append to coordX(coordStep)
                            %coordX
                            miniCoordStep = miniCoordStep + 1;
                        end

                        %miniCoordStep = 1;
                        %coordStep
                        coordX(coordStep) = str2num(coordXx);
                        %size(coordX)
                        usedX = 1;
                        usedT = 0;
                    end

                    %Here we are checking the Y coordniate      

                    if stringCoords(k + miniCoordStep) == ',' && usedX == 1 

                        miniCoordStep = miniCoordStep + 1;   
                        coordYy = stringCoords(k + miniCoordStep);
                        miniCoordStep = miniCoordStep + 1;

                        while stringCoords(k + miniCoordStep) ~= ','

                            coordYy = [coordYy, stringCoords(k + miniCoordStep)]; % we need to append to coordY(coordStep)
                            miniCoordStep = miniCoordStep + 1;
                        end

                        %miniCoordStep = 1;
                        %coordStep
                        usedX = 0;
                        usedY = 1;
                        coordYy = str2num(coordYy);
                        coordY(coordStep) = coordYy;

                    end

                    if stringCoords(k + miniCoordStep) == ',' && usedY == 1 

                        miniCoordStep = miniCoordStep + 1;   
                        coordTt = stringCoords(k + miniCoordStep);
                        miniCoordStep = miniCoordStep + 1;

                        while stringCoords(k + miniCoordStep) ~= ')'

                            coordTt = [coordTt, stringCoords(k + miniCoordStep)];
                            miniCoordStep = miniCoordStep + 1;

                        end

                        coordT(coordStep) = str2num(coordTt);

                        %Reset to beginning conditions
                        %coordStep
                        miniCoordStep = 1;
                        coordStep = coordStep + 1;
                        usedY = 0;
                        usedT = 1;

                    end

                end
             %k

            end

        end
        
        
        function [vx, vy, vx_gc, vy_gc, t] = getRastor( ...
                rastor_string_edit, ...
                rastor_ramp, ...
                time_step_in_us, ...
                volts_scale, ...
                filter_width ...
                )

            % By Kurt Schlueter 2013
            % This function creates the custom rastor waveform from the
            % variables in the gui.
            
            % @parameter rastor_string_edit (char): (sig_x, sig_y,ms),(sig_x, sig_y, ms) ...
            % @parameter rastor_ramp (double): ms for transit between rastor points
            % @parameter time_step_in_us (double): us between time samples 
 
            %This is where we grab the string for the coordinates and parse it down
            %into x y and t numbers that we can use. getRastorString(..)

            [coordX, coordY, coordT] = ScannerCore.getRastorString(rastor_string_edit);

            rampTime = rastor_ramp;

            %Here we create the total time that we will not use til the end.  
            totalTime = 0;
            for tt = 1:1:length(coordT)
                totalTime = totalTime + coordT(tt); % ms
            end
            
            % Add ramps between each rastor point
            totalTime = totalTime + rampTime*(length(coordT)); %ms
            
            % 2013.05.22 CNA + KBS
            % Changing third input from having units of sampls/ms to having
            % units of us.  Need to compute samples/ms so we can reuse
            % Kurt's remaining code unaltered
            
            time_step_in_ms = time_step_in_us/1000;
            samples = ceil(totalTime/time_step_in_ms); 
            samples_per_ms = samples/totalTime;
            
            
            
            timeInflate = samples_per_ms; % timeInflate = samples/ms

            placeH = 0;

            vx = zeros(1, samples);
            vy = zeros(1, samples);
            t = zeros(1, samples);

            %This is the for loop that assigns the values of vx and vy to the
            %appropriate instance in time. Im am sure there is a better way to do this
            %but this works for now.
            for k = 1:1:length(coordX)

                if k == 1

                    for xx = 1:1:(coordT(k)*timeInflate)
                        vx(xx) = coordX(k);
                        vy(xx) = coordY(k);
                    end
                    placeH = xx + 1;
                    %placeH = xx;
                else

                    if rampTime ~= 0

                        %This is for the slope/transit ramp
                        for xx = placeH:1:(placeH+((rampTime*timeInflate))-1)
                            vx(xx) = ((((coordX(k)-coordX(k-1)))/(rampTime*timeInflate))*(xx-placeH)) + coordX(k - 1);
                            vy(xx) = ((((coordY(k)-coordY(k-1)))/(rampTime*timeInflate))*(xx-placeH)) + coordY(k - 1);
                        end
                        placeH = xx + 1;
                        %placeH = xx; 
                    end

                    for xx = placeH:1:((placeH + (coordT(k)*timeInflate))-1)
                        vx(xx) = coordX(k);
                        vy(xx) = coordY(k);
                    end
                    placeH = xx + 1;
                    %placeH =xx;


                    % This is for the slope/transit ramp at the end of the waveform so
                    % that it can loop back to the begining  
                    if k == length(coordX)
                        for xx = placeH:1:(placeH+((rampTime*timeInflate))-1)
                            vx(xx) = ((((coordX(1)-coordX(k)))/(rampTime*timeInflate))*(xx-placeH)) + coordX(k);
                            vy(xx) = ((((coordY(1)-coordY(k)))/(rampTime*timeInflate))*(xx-placeH)) + coordY(k);
                        end
                        %placeH = xx; 
                    end

                end

            end
            
            
            % scale
            
            vx = vx*volts_scale;
            vy = vy*volts_scale;
            vx_gc = vx;
            vy_gc = vy;
            
            time_step = time_step_in_us * 1e-6;
            t = 0 : time_step : (length(vx) - 1) * time_step;
            
            % plot(t*1000,vx_gc,'r',t*1000,vy_gc,'b')
            % % max(t)
            % length(vx_gc)
            % length(vy_gc)


            %ASK CHRIS. Filter/Fourier
            %=======================================================================

            % Compute FT and filter.  First, we'll wrap the ends so that we can make
            % this beast not have a discontinuity at the endpoints!
            
            vx = ScannerCore.lowpass(vx, t, filter_width);
            vy = ScannerCore.lowpass(vy, t, filter_width);
            
        end
        
        function out = lowpass(v, t, hz)
            
            shift_num = 10;

            v = circshift(v',shift_num)';
            f = ScannerCore.space2freq(t);
            V = fftshift(fft(v));
            
%             if pole_count == 1;
%                 filt = rect(f,2*hz);
%             else
%                 
%             end
            
            filt = exp(-(f/hz).^6/2); 

            

            V_filt = filt.*V;
            v_filt = real(ifft(ifftshift(V_filt)));
            
%             figure
%             hold on
%             plot(f, V, 'b');
%             plot(f, V_filt, 'r');
%             legend({'fft(v)', 'filt'});


            % Inverse circleshift to get there real (smoothed) signals back
            v_filt = circshift(v_filt',-shift_num)';
            
            out = v_filt;
            
        end
        
        
        function [st] = getSerpentine(...
                dSigX, ...
                dSigY, ...
                dNumX, ...
                dNumY, ...
                dOffsetX, ...
                dOffsetY, ...
                dPeriod, ...
                dScale, ...
                dFiltHz, ...
                dTimeStep)
            
            % Pre scale dSigX and dSigY so they are each two partial length
            % wider.  Partial length is 
            
            %{
            dSigX = dSigX + 2*dSigX/(dNumX - 1);
            dSigY = dSigY + 2*dSigY/(dNumY - 1);
            %}
            
            % Scale at the very end
            
            dXAmp = dSigX;
            dYAmp = dSigY;
            
            % Number of samples in full fill
            
            dN = round(dPeriod/dTimeStep);

            % Can work out (x,y) pos in terms of distance, or time.  I
            % like thinking about one fill as a line of length:
            
            dLength = 2*dYAmp + dNumY*dXAmp + 2*dXAmp + dNumX*dYAmp;
            
            % Points in full lines
            
            dNX = floor(dXAmp/dLength*dN); % lr
            dNY = floor(dYAmp/dLength*dN); % ud

            % Points in partial lines (first compute length of partial
            % lines)
            
            dLengthXPartial = dXAmp/(dNumX - 1);
            dLengthYPartial = dYAmp/(dNumY - 1);
            
            dNXPartial = floor(dLengthXPartial/dLength*dN);
            dNYPartial = floor(dLengthYPartial/dLength*dN);

            % First set of in horizontal lines

            xrow = linspace(-dXAmp/2, dXAmp/2, dNX);
            yrow = linspace(-dYAmp/2, dYAmp/2, dNY);

            h_x = [];
            h_y = [];
            h_x_full = [];
            h_y_full = [];
            
            % Do the serpentine dominated by horizontal lines

            for n = 0:dNumY/2 - 1

                if (n == dNumY/2 - 1)
                    y1 = n*2*dLengthYPartial - dYAmp/2;
                    y2 = (n + 1)*2*dLengthYPartial - dLengthYPartial - dYAmp/2;
                    yrow_partial = linspace(y1, y2, dNYPartial/2);
                else
                    y1 = n*2*dLengthYPartial - dYAmp/2;
                    y2 = (n + 1)*2*dLengthYPartial - dYAmp/2;
                    yrow_partial = linspace(y1, y2, dNYPartial);
                end


                if mod(n,2) == 0
                    
                    % x: left-to-right
                    h_x(end + 1: end + dNX) = xrow;
                    % x: fixed at right most spot
                    h_x(end + 1: end + length(yrow_partial)) = dXAmp/2;

                    % y: fixed at most negative spot
                    h_y(end + 1: end + dNX) = y1;
                    % y: down to up line
                    h_y(end + 1: end + length(yrow_partial)) = yrow_partial;

                else

                    
                    % x: right-to-left
                    h_x(end + 1: end + dNX) = fliplr(xrow);
                    % x: fixed at left most spot
                    h_x(end + 1: end + length(yrow_partial)) = -dXAmp/2;

                    
                    h_y(end + 1: end + dNX) = y1;
                    h_y(end + 1: end + length(yrow_partial)) = yrow_partial;      

                end

            end
            
            if (mod(dNumX, 4) == 0)
                h_x_full = [h_x, h_x];
            else
                h_x_full = [h_x, -h_x];
            end

            h_y_full = [h_y, -h_y];
             
            
            % Do the serpentine dominated by vertical lines
            
            v_x = [];
            v_y = [];

            for n = 0:dNumX/2 - 1


                if (n == dNumX/2 - 1)
                    x1 = n*2*dLengthXPartial - dXAmp/2;
                    x2 = (n + 1)*2*dLengthXPartial - dLengthXPartial - dXAmp/2;
                    xrow_partial = linspace(x1, x2, dNXPartial/2);
                else
                    x1 = n*2*dLengthXPartial - dXAmp/2;
                    x2 = (n + 1)*2*dLengthXPartial - dXAmp/2;
                    xrow_partial = linspace(x1, x2, dNXPartial);
                end


                if mod(n,2) == 0

                    % x: left most spot
                    v_x(end + 1: end + dNY) = x1;
                    % x: left to right
                    v_x(end + 1: end + length(xrow_partial)) = xrow_partial;

                    % y: bottom to top
                    v_y(end + 1: end + dNY) = yrow;
                    % y: top most spot
                    v_y(end + 1: end + length(xrow_partial)) = dYAmp/2;

                else
                    
                    % x: left most spot
                    v_x(end + 1: end + dNY) = x1;
                    % x: left to right
                    v_x(end + 1: end + length(xrow_partial)) = xrow_partial;

                    % y: top to bottom
                    v_y(end + 1: end + dNY) = fliplr(yrow);
                    % y: bottom most spot
                    v_y(end + 1: end + length(xrow_partial)) = -dYAmp/2;


                end

            end

            v_x_full = [v_x, -v_x];

            if (mod(dNumX, 4) == 0)
                v_y_full = [v_y, v_y];
            else
                v_y_full = [v_y, -v_y];
            end

            x = ([h_x_full, v_x_full] + dOffsetX)*dScale;
            y = ([h_y_full, v_y_full] + dOffsetY)*dScale;
            t = 0 : dTimeStep : (length(x) - 1)*dTimeStep;
            
            % Filter
            
            x = ScannerCore.lowpass(x, t, dFiltHz);
            y = ScannerCore.lowpass(y, t, dFiltHz);
            
            % Return
            
            st.dX = x;
            st.dY = y;
            st.dT = t;
        
        end
        
        
        function [st] = getSerpentine2( ...
                dSigX, ...
                dSigY, ...
                dNumX, ...
                dNumY, ...
                dOffsetX, ...
                dOffsetY, ...
                dPeriod, ...
                dScale, ...
                dFiltHz, ...
                dTimeStep)
           
            % Num is a u8 in the GUI; convert to double for use in math
            
            dNumX = double(dNumX);
            dNumY = double(dNumY);
            
            dXAmp = dSigX;
            dYAmp = dSigY;
            
            % Assume constant velocity of beam.  This means length and time are
            % proportional

            dN = round(dPeriod/dTimeStep);

            % Width of X partial
            dXPartial = dXAmp/(double(dNumX) - 1);
            dYPartial = dYAmp/(double(dNumY) - 1);

            % Lowest horizontal line gets half a x partial length added to right
            % Middle horizontal lines get full x partial added (half on each side)
            % Top horizontal line gets half a x partial length added to left


            dLength1 = (dXAmp + dXPartial/2)*2 + (dXAmp + dXPartial)*(dNumY - 2) + dYAmp;

            % Right vertical line gets half a y partial length added to bottom
            % Middle vertical lines get full y partial added (half on top half on bot)
            % Left horizontal line gets half a y partial length added to top

            dLength2 = (dYAmp + dYPartial/2)*2 + (dYAmp + dYPartial)*(dNumY - 2) + dXAmp;

            % Length of full fill

            dLength = dLength1 + dLength2;

            % Distance between samples

            dDelta = dLength/dN; 

            % Draw scan dominated by horizontal line

            h_x = [];
            h_y = [];

            for n = 1:dNumY

                if mod(n, 2) == 0
                    % even
                    % goes right to left.  even are always in the middle so they get
                    % half of a partial on left and right side
                    % baseline start is right; baseline end is left

                    x1 = dXAmp/2 + dXPartial/2;
                    x2 = -dXAmp/2 - dXPartial/2;

                    x = x1:-dDelta:x2;

                else
                    % odd
                    % left to right
                    if n == 1

                        % add half partial on right
                        x1 = -dXAmp/2;
                        x2 = dXAmp/2 + dXPartial/2;

                    elseif n == dNumY

                        % add half partial on left
                        x1 = -dXAmp/2 - dXPartial/2;
                        x2 = dXAmp/2;

                    else

                        % add half partial on right and left
                        x1 = -dXAmp/2 - dXPartial/2;
                        x2 = dXAmp/2 + dXPartial/2;
                    end

                    x = x1:dDelta:x2;


                end

                y1 = (n - 1)*dYPartial - dYAmp/2;
                y2 = (n)*dYPartial - dYAmp/2;


                y = y1:dDelta:y2;

                % Draw horizontal line
                h_x(end + 1: end + length(x)) = x;
                h_y(end + 1: end + length(x)) = y1;

                if (n ~= dNumY)

                    % Draw vert line
                    h_x(end + 1: end + length(y)) = x2;
                    h_y(end + 1: end + length(y)) = y;
                end

            end

            %{
            figure 
            subplot(121)
            hold on
            plot([1:1:length(h_x)], h_x, '.-r')
            plot([1:1:length(h_y)], h_y, '.-b')
            subplot(122)
            plot(h_x, h_y, '.-b')
            %}

            v_x = [];
            v_y = [];

            for n = 1:dNumX

                if mod(n, 2) == 0

                    % even
                    % bottom to top.  even are always in the middle so they get
                    % half of a partial on left and right side
                    % baseline start is right; baseline end is left

                    y1 = -dYAmp/2 - dYPartial/2;
                    y2 = dYAmp/2 + dYPartial/2;

                    y = y1:dDelta:y2;

                else
                    % odd
                    % top to bottom
                    if n == 1

                        % add half partial on bottom

                        y1 = dYAmp/2;
                        y2 = -dYAmp/2 - dYPartial/2;


                    elseif n == dNumX

                        % add half partial on top

                        y1 = dYAmp/2 + dYPartial/2;
                        y2 = -dYAmp/2;


                    else

                        % add half partial on top and bottom

                        y1 = dYAmp/2 + dYPartial/2;
                        y2 = -dYAmp/2 - dYPartial/2;


                    end

                    y = y1:-dDelta:y2;


                end

                % x goes from right to left

                x1 = dXAmp/2 - (n - 1)*dXPartial;
                x2 = dXAmp/2 - (n)*dXPartial;

                x = x1:-dDelta:x2;


                % Draw vertical line
                v_y(end + 1:end + length(y)) = y;
                v_x(end + 1:end + length(y)) = x1;



                if (n ~= dNumX)

                    % Draw horizontal line after

                    v_y(end + 1:end + length(x)) = y2;
                    v_x(end + 1:end + length(x)) = x;

                end

            end

            %{
            figure 
            subplot(121)
            hold on
            plot([1:1:length(v_x)], v_x, '.-r')
            plot([1:1:length(v_y)], v_y, '.-b')
            subplot(122)
            plot(v_x, v_y, '.-b')
            %}

            % Add everything

            x_full = [h_x, v_x];
            y_full = [h_y, v_y];

            %{
            figure 
            subplot(121)
            hold on
            plot([1:1:length(x_full)], x_full, '.-r')
            plot([1:1:length(y_full)], y_full, '.-b')
            subplot(122)
            plot(x_full, y_full, '.-b')
            axis image
            %}
            
            x = (x_full + dOffsetX)*dScale;
            y = (y_full + dOffsetY)*dScale;
            t = 0 : dTimeStep : (length(x) - 1)*dTimeStep;
            
            % Filter
            
            x = ScannerCore.lowpass(x, t, dFiltHz);
            y = ScannerCore.lowpass(y, t, dFiltHz);
            
            % Return
            
            st.dX = x*2;
            st.dY = y*2;
            st.dT = t;
            
        end
        
        function [st] = getSaw( ...
                dSigX, ...
                dPhaseX, ...
                dOffsetX, ...
                dSigY, ...
                dPhaseY, ...
                dOffsetY, ...
                dScale, ...
                dHz, ...
                dFilterHz, ...
                dTimeStep)
            
            % dSig: [0, 1]
            % dPhase: is in units of pi.  I.E., if dPhase = 1, the phase
            % offset is pi
            
            % The multiplication of the saw() result by 2*dHz is because
            % the saw only gets to an amplitude of 1/dHz/2 since that is
            % the period.  We want the output to be normalized to 1 always
            
            dT = 0 : dTimeStep : 1/dHz - dTimeStep;
            dX = (ScannerCore.saw(dT, 1/dHz/2)*dSigX*2*dHz + dOffsetX - dSigX/2)*dScale;
            dY = (ScannerCore.saw(dT, 1/dHz/2)*dSigY*2*dHz + dOffsetY - dSigY/2)*dScale;
                        
            % Do phase with circshift
            dX = circshift(dX', round(dPhaseX/2*1/dHz/dTimeStep))';
            dY = circshift(dY', round(dPhaseY/2*1/dHz/dTimeStep))';
            
            % Lowpass
            dX = ScannerCore.lowpass(dX, dT, dFilterHz);
            dY = ScannerCore.lowpass(dY, dT, dFilterHz);
            
            st.dT = dT;
            st.dX = dX;
            st.dY = dY;
            
            
        end
                
            

    end % Static
end

