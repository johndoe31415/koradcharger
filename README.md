# koradcharger
This is an interface for a Korad KA3005 bench power supply and scripting that
allows computer-controlled CC/CV charging of Li-Ion batteries (e.g., type
18650) along with logging. It has configurable cutoffs for residual current and
time cutoffs as well.

## Usage
First, make sure your home is insured against arson by gross negligence on your
side. Then, hook up your battery to your Korad power supply. The charging application
has several configurable variables, but sensible defaults:

```
usage: charger [-h] [--charge-voltage volts] [--charge-current amps]
               [--cutoff-current amps] [--cutoff-time hours] [-l filename]
               [-v]
               device

Korad power supply Li-Ion charging application.

positional arguments:
  device                Device to connect to.

optional arguments:
  -h, --help            show this help message and exit
  --charge-voltage volts
                        Specifies charging voltage. Defaults to 4.20 V.
  --charge-current amps
                        Specifies charging current. Defaults to 1.40 A.
  --cutoff-current amps
                        Specifies charging cutoff current. Defaults to 0.06 A.
  --cutoff-time hours   Specifies charging cutoff time in hours. Defaults to
                        3.0 hours.
  -l filename, --logfile filename
                        Specifies file to log into. By default, logging is
                        disabled.
  -v, --verbose         Increases verbosity. Can be specified multiple times
                        to increase.
```

For example, to start the chraging process:

```
$ ./charger -l my_battery.log /dev/ttyACM0
```

Then, if you want to plot the log later, you can use the plotting application, which also offers several options:

```
usage: plot [-h] [-a {voltage,current,mah,wh}]
            [-b {voltage,current,mah,wh,none}] [-o pngfile]
            logfile [logfile ...]

Li-Ion charging log plotter.

positional arguments:
  logfile               A charging log or logs that should be plotted.

optional arguments:
  -h, --help            show this help message and exit
  -a {voltage,current,mah,wh}, --axis1 {voltage,current,mah,wh}
                        First axis content. Can be one of voltage, current,
                        mah, wh, defaults to current.
  -b {voltage,current,mah,wh,none}, --axis2 {voltage,current,mah,wh,none}
                        Second axis content. Can be one of voltage, current,
                        mah, wh, none, defaults to mah.
  -o pngfile, --output pngfile
                        Output file to write to. Defaults to
                        charging_graph.png.
```

For example, to plot charging current on the Y1 axis and charge in Watt-Hours on
the Y2 axis, simply do:

```
$ ./plot -a current -b wh -o my_battery.png my_battery.log
```

## Disclaimer
Before you charge your Li-Ion batteries with a bench power supply, make sure
you know what you're doing.  If you burn your house down, that's on you, not
me. Even if I wrote the code.

## License
GNU GPL-3.
