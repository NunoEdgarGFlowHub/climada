function res=climada_damagefunctions_plot(entity,unique_ID_sel,noplot)
% climada
% NAME:
%   climada_damagefunctions_plot
% PURPOSE:
%   Plot the damage functions within entity (if a damagefunctions struct is
%   passed, it works, too). Also allows to obtain one (and only one!)
%   single damage function, see EXAMPLE.
%
%   See also climada_damagefunctions_read and climada_damagefunctions_generate
% CALLING SEQUENCE:
%   climada_damagefunctions_plot(entity,unique_ID_sel)
%   climada_damagefunctions_plot(climada_damagefunctions_read)
% EXAMPLE:
%   entity=climada_entity_load('entity_template');
%   climada_damagefunctions_plot(entity,'TC')
%
%   res=climada_damagefunctions_plot(entity,'FL 001',1); % obtain one curve
%   res.MDD=res.MDD*0.98765; % modify MDD
%   entity=climada_damagefunctions_replace(entity,res); % replace with new
% INPUTS:
%   entity: an entity, see climada_entity_read
%       > promted for if not given (calling climada_entity_load, not
%       climada_entity_read)
%       Works also, if just a damagefunctions structure is passed (i.e. the
%       same as in entity.damagefunctions, as returned by
%       climada_damagefunctions_read)
% OPTIONAL INPUT PARAMETERS:
%   unique_ID_sel: a single unique ID or the first n characters of an ID to
%       plot only selected damage function(s), as in the case of an entity
%       containing many functions, the single panes of the plot might get
%       too small). It is recommended to run climada_damagefunctions_plot 
%       first without specifying a unique_ID_sel and inspect the single 
%       sub-plot headers. Examples are:
%       unique_ID_sel='TC 001' % print only the one curve
%       unique_ID_sel='TC'     % print all TC curves
%   noplot: do NOT plot, just return the requested curves in res (default=0)
% OUTPUTS:
%   a figure (if noplot=0)
%   res: a structure with the last (and only the last) damagefunction, with
%       fields Intensity, MDD, PAA, MDR for further use. Hence res only
%       make sense when called with one unique ID.
% MODIFICATION HISTORY:
% David N. Bresch, david.bresch@gmail.com, 20141121, ICE
% David N. Bresch, david.bresch@gmail.com, 20141214, unique_ID_sel added
% David N. Bresch, david.bresch@gmail.com, 20141221, MDR calculated locally and unique_ID_sel improved
% David N. Bresch, david.bresch@gmail.com, 20150206, res returned
% David N. Bresch, david.bresch@gmail.com, 20150225, datenum added
% David N. Bresch, david.bresch@gmail.com, 20160920, damagefunctions.name added
% David N. Bresch, david.bresch@gmail.com, 20160929, damagefunctions.Intensity_unit added
% David N. Bresch, david.bresch@gmail.com, 20170211, using the exact same data to plot as returned in res
% David N. Bresch, david.bresch@gmail.com, 20180713, also return name and Intensity_unit
% David N. Bresch, david.bresch@gmail.com, 20190202, noplot added
%-

res=[]; % init

%global climada_global
if ~climada_init_vars,return;end % init/import global variables

%%if climada_global.verbose_mode,fprintf('*** %s ***\n',mfilename);end % show routine name on stdout

% poor man's version to check arguments
if ~exist('entity','var'),entity=[];end
if ~exist('unique_ID_sel','var'),unique_ID_sel='';end
if ~exist('noplot','var'),noplot=0;end

% PARAMETERS
%
% set default value for param2 if not given

% prompt for param1 if not given
if isempty(entity),entity=climada_entity_load;end
if isempty(entity),return;end

if isfield(entity,'damagefunctions')
    entity=climada_damagefunctions_map(entity,[],[],1); % silent, just doube check most times
    damagefunctions=entity.damagefunctions;
else
    damagefunctions=entity; % entity is in fact already a damagefunctions struct
    % if not, we learn it the hard way as the code will fail ;-)
end

if ~isfield(damagefunctions,'datenum')
    damagefunctions.datenum=damagefunctions.DamageFunID*0+now; % add datenum
end

if isfield(damagefunctions,'peril_ID')
    % since there might be the same DamageFunID for two different
    % perils, re-define the damage function
    for i=1:length(damagefunctions.DamageFunID)
        unique_ID{i}=sprintf('%s %3.3i',damagefunctions.peril_ID{i},damagefunctions.DamageFunID(i));
    end % i
else
    for i=1:length(damagefunctions.DamageFunID)
        unique_ID{i}=sprintf('%3.3i',damagefunctions.DamageFunID(i));
    end % i
end

unique_IDs=unique(unique_ID);

% we also show MDR, to ease understanding of MDD*PAA
damagefunctions.MDR=damagefunctions.MDD.*damagefunctions.PAA;

% backward compatibility
if ~isfield(damagefunctions,'name')
    damagefunctions.name=repmat({''},size(damagefunctions.MDD));
end
if ~isfield(damagefunctions,'Intensity_unit')
    damagefunctions.Intensity_unit=repmat({''},size(damagefunctions.MDD));
end

if ~isempty(unique_ID_sel)
    % find matching curves
    unique_pos=strncmp(unique_ID_sel,unique_IDs,length(unique_ID_sel));
    % force single damage function to be plotted
    unique_IDs=unique_IDs(unique_pos);
end

% figure number of sub-plots and their arrangement
n_plots=length(unique_IDs);
N_n_plots=ceil(sqrt(n_plots));n_N_plots=N_n_plots-1;
if ~((N_n_plots*n_N_plots)>n_plots),n_N_plots=N_n_plots;end

for ID_i=1:length(unique_IDs)
    if ~noplot,subplot(N_n_plots,n_N_plots,ID_i);end
    dmf_pos=strmatch(unique_IDs{ID_i},unique_ID);
    if ~isempty(dmf_pos)
        if ~noplot,fprintf('plot %i: %s %s\n',ID_i,char(unique_IDs(ID_i)),damagefunctions.name{dmf_pos(1)});end % this way, it's easy to use them (see unique_ID_sel)
        % prep data block and store (last one will be returned)
        res.Intensity=damagefunctions.Intensity(dmf_pos);
        res.MDD=damagefunctions.MDD(dmf_pos);
        res.PAA=damagefunctions.PAA(dmf_pos);
        res.MDR=damagefunctions.MDR(dmf_pos);
        res.DamageFunID=damagefunctions.DamageFunID(dmf_pos);
        res.peril_ID=damagefunctions.peril_ID(dmf_pos);
        res.datenum=damagefunctions.datenum(dmf_pos);
        res.Intensity_unit=damagefunctions.Intensity_unit(dmf_pos); % 20180713
        res.name=damagefunctions.name(dmf_pos); % 20180713
        %
        if ~noplot
            plot(res.Intensity,res.MDR,'-r','LineWidth',2);hold on
            plot(res.Intensity,res.MDD,'-b','LineWidth',2);
            plot(res.Intensity,res.PAA,':g','LineWidth',2);
            axis tight
            set(get(gcf,'CurrentAxes'),'YLim',[0 1]);
            legend('MDR','MDD','PAA','Location','NorthWest');
            xlabel('Intensity','FontSize',9);
            if isfield(entity,'damagefunctions')
                if isfield(entity.damagefunctions,'Intensity_unit')
                    xlabel(['Intensity [' entity.damagefunctions.Intensity_unit{dmf_pos(1)} ']'],'FontSize',9);
                end
            end
            ylabel('MDR')
            title([unique_IDs{ID_i} ' ' damagefunctions.name{dmf_pos(1)}]);
            grid on
            grid minor
        end % noplot
    else
        fprintf('Error: %s not found\n',char(unique_IDs(ID_i))); % this way, it's easy to use them (see unique_ID_sel)
    end
end
if ~noplot
    set(gcf,'Color',[1 1 1]);
    set(gcf,'Name','damagefunctions');
end % noplot

end % climada_damagefunctions_plot