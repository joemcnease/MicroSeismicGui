% Run GUI
function RunMicroSeimsicGUI

  set(0, 'DefaultAxesFontSize', 12);

  fig = figure('Position',[300 100 1400 800],'Name','MicroSeismicGUI',...
              'MenuBar','none','NumberTitle','off');

  % Models
  pickPath = 'picks/picks.txt';
  miniSeedData = MiniSeedData;
  pickData = PickData(pickPath);

  % Views
  EventView(miniSeedData,pickData,fig);
  StationView(miniSeedData,pickData,fig);

  spectrumView = SpectrumView(miniSeedData,pickData,fig);
  hodogramView = HodogramView(miniSeedData,pickData,fig);

  % Controller
  Controller(miniSeedData,pickData,spectrumView,hodogramView,fig);

end