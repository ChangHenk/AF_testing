function varargout = AF_testing(varargin)
% AF_TESTING MATLAB code for AF_testing.fig
%      AF_TESTING, by itself, creates a new AF_TESTING or raises the existing
%      singleton*.
%
%      H = AF_TESTING returns the handle to a new AF_TESTING or the handle to
%      the existing singleton*.
%
%      AF_TESTING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AF_TESTING.M with the given input arguments.
%
%      AF_TESTING('Property','Value',...) creates a new AF_TESTING or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AF_testing_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AF_testing_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AF_testing

% Last Modified by GUIDE v2.5 02-Aug-2021 16:35:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AF_testing_OpeningFcn, ...
                   'gui_OutputFcn',  @AF_testing_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before AF_testing is made visible.
function AF_testing_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AF_testing (see VARARGIN)
% Choose default command line output for AF_testing
warning('off');
handles.output = hObject;
handles.f_stroke = false;
handles.f_hysteresis = false;
handles.f_sens = false;
handles.f_tilt = false;
handles.flag = false;

setPlot(handles);
% 若settings檔案不存在，自動創新的settings檔
if (exist('settings.csv','file') == 0)
    Items = {'Current_step';'Current_increasing_interval';'current_limits';'Tilt';'Stroke';'Hysteresis';'Starting_current';'Sensitivity'};
    Unit = {'mA';'ms';'mA';'min';'um';'um';'mA';'um/mA'};
    Parameter = {'4';'500';'';'';'';'';'';''};
    Lower_spec = {'';'';'1';'1.5';'0.7';'0.3';'1';'0.001'};
    Upper_spec = {'';'';'4095';'2';'0.85';'0.35';'4095';'0.002'};
    T = table(Items, Unit, Parameter, Lower_spec, Upper_spec);
    writetable(T,'settings.csv');
end
% 若result檔案不存在，自動創新的result檔
if (exist('result.csv','file') == 0)
    fid = fopen('result.csv','w');
    fprintf(fid,'%s,%s,%s,%s,%s,%s\n','Time', 'Starting', 'Tilt', 'Stroke', 'Hysteresis', 'Sensitivity');
    fclose('all');
end
% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = AF_testing_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;

%設定標題
function setPlot(handles)

cla(handles.Stroke);
cla(handles.XY);
cla(handles.tilt_xy);
cla(handles.plot2);

title(handles.Stroke,'Stroke-Time');
title(handles.XY,'Tilt-Time');
title(handles.plot2,'Stroke-CMD');
title(handles.tilt_xy,'Tilt: X-Y');

ylabel(handles.Stroke,'Stroke (um)');
ylabel(handles.XY,'Tilt (min)');
ylabel(handles.plot2,'Stroke (um)');
ylabel(handles.tilt_xy,'Y Tilt (min)');

xlabel(handles.Stroke,'Time (s)');
xlabel(handles.XY,'Time (s)');
xlabel(handles.plot2,'CMD');
xlabel(handles.tilt_xy,'X Tilt (min)');

xlim(handles.tilt_xy, [-30,30]);
ylim(handles.tilt_xy, [-30,30]);

for r = 10:10:30
    theta = 0:0.1:2*pi+0.1;
    circle1 = r*cos(theta);
    circle2 = r*sin(theta);
    plot(handles.tilt_xy, circle1, circle2, 'r--', 'linewidth', 1);
end
hold(handles.Stroke,'on');
hold(handles.XY,'on');
hold(handles.plot2,'on');
hold(handles.tilt_xy,'on');

%接收位置
function CMD = getBin(h)

pos = ones(1,12)*(-1);
Pos = '';
count = 1;
c = 0;

while(pos(12) == -1)
    ch = h.inputSingleScan();
    if(ch(1,1) == 1)
        if(c == 0 && count > 1)
            count = count - 1;
        end
        pos(count) = ch(1,2);
        count = count + 1;
        c = 0;
    else
        c = c + 1;
        if(c > 4)
            count = 1;
            pos = ones(1,12)*(-1);
        end
    end
end
for i = 1:12
    Pos = [Pos,num2str(pos(i))];
end
CMD = bin2dec(Pos);

%傳參數到arduino
function MtoA(step,interval,lower_current,upper_current)
daq.getDevices();
out = daq.createSession('ni');
setting = daq.createSession('ni');
flag_out = daq.createSession('ni');
save_clicked = daq.createSession('ni');

out.addDigitalChannel('Dev1','Port2/Line0','OutputOnly');
setting.addDigitalChannel('Dev1','Port1/Line2','InputOnly');
flag_out.addDigitalChannel('Dev1','Port1/Line3','OutputOnly');
save_clicked.addDigitalChannel('Dev1','Port1/Line4','OutputOnly');

num = [step,interval,lower_current,upper_current];

for i = 1:4
    Bin_num = decimalToBinaryVector(num(1,i));
    while(inputSingleScan(setting) == 1)
        outputSingleScan(save_clicked,1);
    end

    for j = 1:length(Bin_num)
        outputSingleScan(flag_out,1);
        outputSingleScan(out,Bin_num(1,j));
        outputSingleScan(flag_out,0);
        pause(0.1);
    end
    pause(0.1);

    while(inputSingleScan(setting) == 0)
        outputSingleScan(save_clicked,0);
    end
    outputSingleScan(save_clicked,1);
end

setting.removeChannel(1);
flag_out.removeChannel(1);
save_clicked.removeChannel(1);
out.removeChannel(1);

%載入setting資料 參數存到matlab,arduino
function saveExcel(hObject, handles)
daq.getDevices();
save_clicked = daq.createSession('ni');
save_clicked.addDigitalChannel('Dev1','Port1/Line4','OutputOnly');

try
    [Items, Unit, Parameter, Lower_spec, Upper_spec] = textread(handles.FileName.String, '%s %s %s %s %s', 'delimiter', ',', 'headerlines', 1);
    f = 1;
catch
    msgbox('Please choose a valid file.');
    f = 0;
end
if(f == 1)
    for i = 1:length(Items)
        switch i
            case 1
                step = str2double(Parameter(i,1));
                handles.step = step;
            case 2
                interval = str2double(Parameter(i,1));
                handles.interval = interval;
            case 3
                lower_current = str2double(Lower_spec(i,1));
                upper_current = str2double(Upper_spec(i,1));
                handles.lower_current = lower_current;
                handles.upper_current = upper_current;
            case 4
                lower_tilt = str2double(Lower_spec(i,1));
                upper_tilt = str2double(Upper_spec(i,1));
                set(handles.max_Tilt,'String',upper_tilt);
                set(handles.min_Tilt,'String',lower_tilt);
                handles.lower_tilt = lower_tilt;
                handles.upper_tilt = upper_tilt;
                handles.f_tilt = true;
            case 5
                lower_stroke = str2double(Lower_spec(i,1));
                upper_stroke = str2double(Upper_spec(i,1));
                set(handles.max_Stroke,'String',upper_stroke);
                set(handles.min_Stroke,'String',lower_stroke);
                handles.lower_stroke = lower_stroke;
                handles.upper_stroke = upper_stroke;
                handles.f_stroke = true;
            case 6
                lower_hysteresis = str2double(Lower_spec(i,1));
                upper_hysteresis = str2double(Upper_spec(i,1));
                set(handles.max_Hysteresis,'String',upper_hysteresis);
                set(handles.min_Hysteresis,'String',lower_hysteresis);
                handles.upper_hysteresis = upper_hysteresis;
                handles.lower_hysteresis = lower_hysteresis;
                handles.f_hysteresis = true;
%             case 7
%                 lower_start = str2double(Lower_spec(i,1));
%                 upper_start = str2double(Upper_spec(i,1));
%                 handles.lower_start = lower_start;
%                 handles.upper_start = upper_start;
            case 8
                lower_sens = str2double(Lower_spec(i,1));
                upper_sens = str2double(Upper_spec(i,1));
                set(handles.max_Sensitivity,'String',upper_sens);
                set(handles.min_Sensitivity,'String',lower_sens);
                handles.lower_sens = lower_sens;
                handles.upper_sens = upper_sens;
                handles.f_sens = true;
        end
        guidata(hObject, handles);
    end
    MtoA(step,interval,lower_current,upper_current);
    outputSingleScan(save_clicked,0);
end
save_clicked.removeChannel(1);

%儲存到result.csv
function writeResult(~, handles)
write_flag = false;
if handles.flag == true
    try
        Tilt = handles.max_tilt;
        Stroke = handles.max_z;
        Hysteresis = handles.max_hys;
        Sensitivity = handles.max_sens;
        Starting = handles.start_CMD;
        Time = {datestr(now)};
        write_flag = true;
    catch
        write_flag = false;
    end
end

if write_flag == true
    if(Stroke == -1000)
        Stroke = nan('double');
    end
    if(Hysteresis == -1000)
        Hysteresis = nan('double');
    end
    if(Sensitivity == -1000)
        Sensitivity = nan('double');
    end
    if(Tilt == -1000)
        Tilt = nan('double');
    end
    T = readtable('result.csv');
    table1 = table(Time, Starting, Tilt, Stroke, Hysteresis, Sensitivity);
    T = [T;table1];
    writetable(T,'result.csv');
end

%Stroke
function max_stroke = calStroke(handles, max_z, max_stroke)
max_stroke = max(max_z, max_stroke);

if(handles.check_Stroke.Value == 1)
    if(handles.f_stroke == true)
        if(max_stroke > handles.upper_stroke || max_stroke < handles.lower_stroke)
            if(max_stroke == -1000)
                max_stroke = 'null';
            end
            set(handles.text_stroke,'String',max_stroke,'ForegroundColor',[1,0,0]);
        else
            set(handles.text_stroke,'String',max_stroke,'ForegroundColor',[0,0,0]);
        end
    end
else
    set(handles.text_stroke,'String','null','ForegroundColor',[0,0,0]);
end
if(string(max_stroke) == 'null')
    max_stroke = -1000;
end

%Hysteresis
function [max_hys, hys_up, hys_down] = calHysteresis(handles, CMD, ex_CMD, mean_z, hys_up, hys_down, max_hys)
if(CMD > 0)
    if((CMD - ex_CMD) > 0)
        hys_up(CMD+1) = mean_z;
    else
        hys_down(CMD+1) = mean_z;
    end
end
%法一
for j = handles.lower_current:handles.step:handles.upper_current
    if(hys_down(j+1) ~= -1000 && hys_up(j+1) ~= -1000)
        hys = hys_down(j+1)-hys_up(j+1);
        max_hys = max(max_hys, hys);
    end
end

%法二
% i = find(hys_down ~= -1000 & hys_up ~= -1000);
% if(isempty(i) == 1)
%     max_hys = -1000;
% else
%     max_hys = max(max(hys_down(i)-hys_up(i)), max_hys);
% end

if(handles.check_Hysteresis.Value == 1)
    if(handles.f_hysteresis == true)
        if max_hys > handles.upper_hysteresis || max_hys < handles.lower_hysteresis
            if(max_hys == -1000)
                max_hys = 'null';
            end
            set(handles.text_hysteresis,'String',max_hys,'ForegroundColor',[1,0,0]);
        else
            set(handles.text_hysteresis,'String',max_hys,'ForegroundColor',[0,0,0]);
        end
    end
else
    set(handles.text_hysteresis,'String','null','ForegroundColor',[0,0,0]);
end
if(string(max_hys) =='null')
    max_hys = -1000;
end

%Sensitivity
function max_sens = calSensitivity(handles, mean_z, temp_data, CMD, temp_CMD, max_sens)
temp_max_sens = -1000;

if(temp_CMD ~= -1)
    temp_max_sens = abs((mean_z - temp_data)/(CMD - temp_CMD));
end
if(temp_max_sens < inf)
    max_sens = max(max_sens, temp_max_sens);
end

if(handles.check_Sensitivity.Value == 1)
    if(handles.f_sens == true)
        if(max_sens > handles.upper_sens || max_sens < handles.lower_sens)
            if(max_sens == -1000)
                max_sens = 'null';
            end
            set(handles.text_sensitivity,'String',max_sens,'ForegroundColor',[1,0,0]);
        else
            set(handles.text_sensitivity,'String',max_sens,'ForegroundColor',[0,0,0]);
        end
    end
else
    set(handles.text_sensitivity,'String','null','ForegroundColor',[0,0,0]);
end
if(string(max_sens) == 'null')
    max_sens = -1000;
end

%Start_CMD
function start_CMD = calStart(temp_CMD, CMD, start_CMD)
if(temp_CMD == -1)
    start_CMD = CMD;
end

%Tilt
function max_tilt = calTilt(handles, max_x, max_y, max_tilt)
tilt = sqrt(max_x^2+max_y^2);
max_tilt = max(max_tilt,tilt);

if(handles.check_Tilt.Value == 1)
    if(handles.f_tilt == true)
        if(max_tilt > handles.upper_tilt || max_tilt < handles.lower_tilt)
            set(handles.text_tilt,'String',max_tilt,'ForegroundColor',[1,0,0]);
        else
            set(handles.text_tilt,'String',max_tilt,'ForegroundColor',[0,0,0]);
        end
    end
else
    set(handles.text_tilt,'String','null','ForegroundColor',[0,0,0]);
end

%NG/OK
function Set_status(handles, max_stroke, max_hys, max_sens, max_tilt)

status = [0,0,0,0];
if ((max(max_stroke, handles.upper_stroke) == max_stroke) || (min(max_stroke, handles.lower_stroke) == max_stroke))
    status(1,1) = 0;
else
    status(1,1) = 1;
end
if ((max(max_hys, handles.upper_hysteresis) == max_hys) || (min(max_hys, handles.lower_hysteresis) == max_hys))
    status(1,2) = 0;
else
    status(1,2) = 1;
end
if ((max(max_sens, handles.upper_sens) == max_sens) || (min(max_sens, handles.lower_sens) == max_sens))
    status(1,3) = 0;
else
    status(1,3) = 1;
end
if ((max(max_tilt, handles.upper_tilt) == max_tilt) || (min(max_tilt, handles.lower_tilt) == max_tilt))
    status(1,4) = 0;
else
    status(1,4) = 1;
end
if(all(status) == true)
    set(handles.Status, 'String', 'OK', 'ForegroundColor', [0,1,0]);
else
    set(handles.Status, 'String', 'NG', 'ForegroundColor', [1,0,0]);
end

%button_Load
function button_Load_Callback(~, ~, handles)
% hObject    handle to button_Load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename, pathname] = uigetfile('.csv','csv(*.csv)','Load File','MultiSelect','off');
if(string(filename) == 'settings.csv')
    set(handles.FileName,'String',[pathname,filename]);
    winopen([pathname,filename]);
else
    msgbox('Please choose "settings" file.');
end
    
%button_Save
function button_Save_Callback(hObject, ~, handles)
% hObject    handle to button_Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.Button_Start,'Enable','off');
saveExcel(hObject, handles);
set(handles.Button_Start,'Enable','on');

%Button_Start
function Button_Start_Callback(hObject, ~, handles)
%initial
set(handles.button_Save,'Enable','off');
set(handles.Button_Start,'String','Running','Enable','off');
max_x = -1000;
max_y = -1000;
max_z = -1000;
max_hys = -1000;
temp_CMD = -1;
temp_data = -1;
% temp_x = -1;  %V2
% temp_y = -1;  %V2
% temp_z = -1;  %V2
% temp_time = 0;  %V2
max_sens = -1000;
max_tilt = -1000;
start_CMD = -1000;
max_stroke = -1000;
t = 0;
k = 0;
f = 0;
r = 0;

try
    hys_up = ones(1,handles.upper_current+1)*(-1000);
    hys_down = ones(1,handles.upper_current+1)*(-1000);
catch
    msgbox('Please press save button first.');
    set(handles.button_Save,'Enable','on');
    set(handles.Button_Start,'String','Start','Enable','on');
    return;
end

if (exist('result.csv','file') == 0)
    fid = fopen('result.csv','w');
    fprintf(fid,'%s,%s,%s,%s,%s,%s\n','Time', 'Starting', 'Tilt', 'Stroke', 'Hysteresis', 'Sensitivity');
    fclose('all');
end

handles.flag = true;
daq.reset();

setPlot(handles);

set(handles.text_stroke,'String','null','ForegroundColor',[0,0,0]);
set(handles.text_hysteresis,'String','null','ForegroundColor',[0,0,0]);
set(handles.text_sensitivity,'String','null','ForegroundColor',[0,0,0]);
set(handles.text_tilt,'String','null','ForegroundColor',[0,0,0]);
set(handles.Status,'String','NG/OK','ForegroundColor',[0,0,0]);

s = daq.createSession('ni');
tr = daq.createSession('ni');
h = daq.createSession('ni');

s.ExternalTriggerTimeout = 10;
s.DurationInSeconds = 0.1;
s.Rate = 10000;

s.addAnalogInputChannel('Dev1','ai0','Voltage');
s.addAnalogInputChannel('Dev1','ai1','Voltage');
s.addAnalogInputChannel('Dev1','ai2','Voltage');
h.addDigitalChannel('Dev1','Port1/Line3','InputOnly');
h.addDigitalChannel('Dev1','Port2/Line0','InputOnly');
tr.addDigitalChannel('Dev1','Port0/Line3','OutputOnly');
s.addTriggerConnection('external','Dev1/PFI0','StartTrigger');
outputSingleScan(tr,1);

while handles.flag == true
    tic1 = tic;
    try
        CMD = getBin(h);
        [data, timestamps] = s.startForeground();
        f = 1;
    catch
        if(handles.Button_Start.Value == 0)
            return;
        end
        handles = guidata(hObject);
        f = 0;
    end
    if(f == 1)
        data_x = data(:,1)*18.007+0.0186;
        data_y = data(:,2)*18.007-0.0204;
        data_z = data(:,3)*800.63-0.2669;

        max_x = max(max(data_x),max_x);
        max_y = max(max(data_y),max_y);
        max_z = max(max(data_z),max_z);

        mean_x = mean(data_x);
        mean_y = mean(data_y);
        mean_z = mean(data_z);

        toc1 = toc(tic1);
        t = t + handles.interval/1000;
        
        if(t >= k+30)
            k = k + 30;
        end

        %plotting
        %plot (x,y,z)-t     V1
        plot(handles.Stroke, timestamps*toc1*10 + t, data_z,'r');
        xlim(handles.Stroke, [0,30+k]);
        hold(handles.Stroke,'on');
        plot(handles.XY, timestamps*toc1*10 + t, data_x,'b', timestamps*toc1*10 + t, data_y,'g');
        xlim(handles.XY, [0,30+k]);
        hold(handles.XY,'on');
        
        %plot (x,y,z)-t     %V2
%         if(temp_z == -1)
%             temp_x = max_x;
%             temp_y = max_y;
%             temp_z = max_z;
%         end
%         plot(handles.Stroke, linspace(0, t, 1000), linspace(temp_z, mean_z, 1000), 'r');
%         hold(handles.Stroke,'on');
%         plot(handles.XY, linspace(0, t, 1000), linspace(temp_x, mean_x, 1000), 'b', linspace(0, t, 1000), linspace(temp_y, mean_y, 1000), 'g');
%         hold(handles.XY,'on');
% 
%         temp_x = mean_x;
%         temp_y = mean_y;
%         temp_z = mean_z;
        %V2   %V2   %V2
        
        %plot tilt_xy
        plot(handles.tilt_xy, mean_x, mean_y, '*g');
        hold(handles.tilt_xy,'on');
        %plot z-CMD
        if (temp_CMD ~= -1)
            plot(handles.plot2, linspace(temp_CMD,CMD,handles.step), linspace(temp_data,mean_z,handles.step),'r.-');
            xlim(handles.plot2, [handles.lower_current-100,handles.upper_current+100]);
            hold(handles.plot2,'on');
        end

        %Calculations
        max_stroke = calStroke(handles, max_z, max_stroke);
        [max_hys, hys_up, hys_down] = calHysteresis(handles, CMD, temp_CMD, mean_z, hys_up, hys_down, max_hys);
        max_sens = calSensitivity(handles, mean_z, temp_data, CMD, temp_CMD, max_sens);
        start_CMD = calStart(temp_CMD, CMD, start_CMD);
        max_tilt = calTilt(handles, max_x, max_y, max_tilt);

        handles.max_z = max_stroke;
        handles.max_hys = max_hys;
        handles.max_sens = max_sens;
        handles.start_CMD = start_CMD;
        handles.max_tilt = max_tilt;
        guidata(hObject, handles);
        
        if(CMD == start_CMD)
            r = r + 1;
        end
        if(r == 3)
              break;
        end

        temp_CMD = CMD;
        temp_data = mean_z;
    end
%     toc(tic1)
end
set(handles.button_Save,'Enable','on');
set(handles.Button_Start,'String','Start','Enable','on');

if(r >= 3)
    Set_status(handles, max_stroke, max_hys, max_sens, max_tilt);
    writeResult(hObject, handles);
end

%Button_Stop
function button_Stop_Callback(hObject, ~, handles)
% hObject    handle to button_Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.flag = false;
guidata(hObject, handles);
daq.reset();
set(handles.button_Save,'Enable','on');
set(handles.Button_Start,'Enable','on');

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: delete(hObject) closes the figure
daqreset;
delete(hObject);

% --- Executes on button press in checkbox7.
function checkbox7_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox7
% --- Executes on button press in checkbox8.
function checkbox8_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox8
% --- Executes on button press in checkbox9.
function checkbox9_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox9
% --- Executes on button press in checkbox10.
function checkbox10_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox10
% --- Executes on button press in checkbox11.
function checkbox11_Callback(hObject, ~, handles)
% hObject    handle to checkbox11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox11
% --- Executes on button press in checkbox12.
function checkbox12_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox12
% --- Executes on button press in checkbox13.
function checkbox13_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox13
% --- Executes on button press in checkbox14.
function checkbox14_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox14


% --- Executes on button press in check_Stroke.
function check_Stroke_Callback(hObject, eventdata, handles)
% hObject    handle to check_Stroke (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of check_Stroke
% --- Executes on button press in check_Hysteresis.
function check_Hysteresis_Callback(hObject, eventdata, handles)
% hObject    handle to check_Hysteresis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of check_Hysteresis
% --- Executes on button press in check_Sensitivity.
function check_Sensitivity_Callback(hObject, eventdata, handles)
% hObject    handle to check_Sensitivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of check_Sensitivity
% --- Executes on button press in check_Linearity.
function check_Linearity_Callback(hObject, eventdata, handles)
% hObject    handle to check_Linearity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of check_Linearity
% --- Executes on button press in check_Current.
function check_Current_Callback(hObject, eventdata, handles)
% hObject    handle to check_Current (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of check_Current
function FileName_Callback(hObject, eventdata, handles)
% hObject    handle to FileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of FileName as text
%        str2double(get(hObject,'String')) returns contents of FileName as a double
% --- Executes during object creation, after setting all properties.
function FileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function PathName_Callback(hObject, eventdata, handles)
% hObject    handle to PathName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of PathName as text
%        str2double(get(hObject,'String')) returns contents of PathName as a double
% --- Executes during object creation, after setting all properties.
function PathName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PathName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes on button press in check_Tilt.
function check_Tilt_Callback(hObject, ~, handles)
% hObject    handle to check_Tilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of check_Tilt

function edit11_Callback(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edit11 as text
%        str2double(get(hObject,'String')) returns contents of edit11 as a double

% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in checkbox16.
function checkbox16_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox16

% --- Executes on button press in checkbox17.
function checkbox17_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox17

% --- Executes on button press in checkbox18.
function checkbox18_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox18

% --- Executes on button press in checkbox19.
function checkbox19_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox19

% --- Executes on button press in checkbox20.
function checkbox20_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox20

% --- Executes on button press in checkbox21.
function checkbox21_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox21

% --- Executes on button press in checkbox22.
function checkbox22_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox22

% --- Executes on button press in checkbox23.
function checkbox23_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox23

% --- Executes on button press in checkbox24.
function checkbox24_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox24

% --- Executes on button press in checkbox25.
function checkbox25_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox25

% --- Executes on button press in checkbox26.
function checkbox26_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox26

% --- Executes on button press in checkbox27.
function checkbox27_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox27

% --- Executes on button press in checkbox28.
function checkbox28_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkbox28

function max_Stroke_Callback(hObject, eventdata, handles)
% hObject    handle to max_Stroke (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of max_Stroke as text
%        str2double(get(hObject,'String')) returns contents of max_Stroke as a double

% --- Executes during object creation, after setting all properties.
function max_Stroke_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_Stroke (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function min_Stroke_Callback(hObject, eventdata, handles)
% hObject    handle to min_Stroke (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of min_Stroke as text
%        str2double(get(hObject,'String')) returns contents of min_Stroke as a double

% --- Executes during object creation, after setting all properties.
function min_Stroke_CreateFcn(hObject, eventdata, handles)
% hObject    handle to min_Stroke (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function max_Hysteresis_Callback(hObject, eventdata, handles)
% hObject    handle to max_Hysteresis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of max_Hysteresis as text
%        str2double(get(hObject,'String')) returns contents of max_Hysteresis as a double

% --- Executes during object creation, after setting all properties.
function max_Hysteresis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_Hysteresis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function min_Hysteresis_Callback(hObject, eventdata, handles)
% hObject    handle to min_Hysteresis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of min_Hysteresis as text
%        str2double(get(hObject,'String')) returns contents of min_Hysteresis as a double

% --- Executes during object creation, after setting all properties.
function min_Hysteresis_CreateFcn(hObject, eventdata, handles)
% hObject    handle to min_Hysteresis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function max_Sensitivity_Callback(hObject, eventdata, handles)
% hObject    handle to max_Sensitivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of max_Sensitivity as text
%        str2double(get(hObject,'String')) returns contents of max_Sensitivity as a double

% --- Executes during object creation, after setting all properties.
function max_Sensitivity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_Sensitivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function min_Sensitivity_Callback(hObject, eventdata, handles)
% hObject    handle to min_Sensitivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of min_Sensitivity as text
%        str2double(get(hObject,'String')) returns contents of min_Sensitivity as a double

% --- Executes during object creation, after setting all properties.
function min_Sensitivity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to min_Sensitivity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function max_Tilt_Callback(hObject, eventdata, handles)
% hObject    handle to max_Tilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of max_Tilt as text
%        str2double(get(hObject,'String')) returns contents of max_Tilt as a double

% --- Executes during object creation, after setting all properties.
function max_Tilt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to max_Tilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function min_Tilt_Callback(hObject, eventdata, handles)
% hObject    handle to min_Tilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of min_Tilt as text
%        str2double(get(hObject,'String')) returns contents of min_Tilt as a double

% --- Executes during object creation, after setting all properties.
function min_Tilt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to min_Tilt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
