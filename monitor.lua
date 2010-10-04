require("iuplua")
require("iupluacontrols")
require("iuplua_pplot")

mnu = iup.menu
{
    iup.submenu
    {
        iup.menu
        {
            iup.item
            {
                title = "IupItem 1 Checked",
                value = "ON"
            },
            iup.separator{},
            iup.item
            {
                title = "IupItem 2 Disabled",
                active = "NO"
            },
            iup.separator{},
            iup.item
            {
                title = "Quit"
            }
        },
        title = "File"
    },
    iup.item
    {
        title = "Radio"
    },
    iup.item
    {
        title = "GPS"
    },
    iup.submenu
    {
        iup.menu
        {
            iup.item
            {
                title = "About"
            }
        },
        title = "Help"
    }
}

plot_altitude = iup.pplot
{
    title = "A simple XY Plot",
    MARGINBOTTOM = "35",
    MARGINLEFT = "35",
    AXS_XLABEL = "X",
    AXS_YLABEL = "Y"
}

iup.PPlotBegin(plot_altitude, 0)
iup.PPlotAdd(plot_altitude, 0, 0)
iup.PPlotAdd(plot_altitude, 5, 5)
iup.PPlotAdd(plot_altitude, 10, 7)
iup.PPlotEnd(plot_altitude)

plot_location = iup.pplot
{
    title = "A simple XY Plot",
    MARGINBOTTOM = "35",
    MARGINLEFT = "35",
    AXS_XLABEL = "X",
    AXS_YLABEL = "Y"
}

iup.PPlotBegin(plot_location, 0)
iup.PPlotAdd(plot_location, 0, 0)
iup.PPlotAdd(plot_location, 5, 5)
iup.PPlotAdd(plot_location, 10, 7)
iup.PPlotEnd(plot_location)

dlg = iup.dialog
{
    iup.split
    {
        iup.split
        {
            iup.frame
            {
                plot_altitude,
                title = "Altitude"
            },
            iup.frame
            {
                plot_location,
                title = "Location"
            }
        },
        iup.split
        {
            iup.frame
            {
                iup.multiline
                {
                    expand="yes", 
                    readonly="yes", 
                    bgcolor="232 232 232", 
                    font = "Monospace, 10",
                    appendnewline = "No",
                },
                title = "Radio Log"
            },
            iup.frame
            {
                iup.multiline
                {
                    expand="yes", 
                    readonly="yes", 
                    bgcolor="232 232 232", 
                    font = "Monospace, 10",
                    appendnewline = "No"
                },
                title = "GPS Log"
            }
        },
        direction = "HORIZONTAL"
    },
    title = "IupDialog Title",
    menu = mnu,
    size = "HALFxHALF",
    placement = "maximized"
}

function draw_plot()
end

function dlg:close_cb()
    iup.ExitLoop()
    dlg:destroy()
    return iup.IGNORE
end

dlg:show()

if (iup.MainLoopLevel() == 0) then
    iup.MainLoop()
end
