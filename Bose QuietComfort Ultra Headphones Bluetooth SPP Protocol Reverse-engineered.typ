#set heading(numbering: "1.1.1")
#set page(numbering: "1")

#show link: underline
#show link: set text(blue)

#show title: set text(size: 26pt)
#show title: set align(center)
#title[
  #link("https://support.bose.com/s/product/bose-quietcomfort-ultra-headphones/01t8c00000QEpaxAAD?language=en_US")[Bose QuietComfort Ultra Headphones] Bluetooth SPP Protocol Reverse‑engineered
]
#set document(
  title: "Bose QuietComfort Ultra Headphones Bluetooth SPP Protocol Reverse‑engineered",
  author: "Krzysztof Kwiatkowski"
)
#linebreak()
#align(center)[
  #text(size: 20pt, [
    Krzysztof Kwiatkowski
  ]) \
  #text(size: 17pt, [
    https://docentcompany.com
  ])
]


#align(center + horizon)[
  #text(size: 17pt, [

    #datetime.today().display()

    Version 1
  ])
]

#pagebreak()
#outline()
#pagebreak()

#let section(level, body) = {
  heading(level: level, outlined: false, numbering: none, [#body])
}

#let least-significant-bit-index(start, end: 0) = {
  range(start, end, step: -1).map(i => str(i))
}

// Customizable options for a split-box border:
#let default-border = (
  // The starting and ending lines
  above: line(length: 100%),
  below: line(length: 100%),
  // Lines to put between the box over multiple pages
  btwn-above: line(length: 100%, stroke: (dash: "dotted")),
  btwn-below: line(length: 100%, stroke: (dash: "dotted")),
  // Left/right lines
  // These *must* use `grid.vline()`, otherwise you will get an error.
  // To remove the lines, set them to: `grid.vline(stroke: none)`.
  // You could probably configure this better with a rowspan, but I'm lazy.
  left: grid.vline(),
  right: grid.vline(),
)
#import "utils.typ": counter-family, zig-zag

// Create a box for content which spans multiple pages/columns and
// has custom borders above and below the column-break.
#let split-box(
  // Set the border dictionary, see `default-border` above for options
  border: default-border,
  // The cell to place content in, this should resolve to a `grid.cell`
  cell: grid.cell.with(inset: 5pt),
  // The last positional arg or args are your actual content
  // Any extra named args will be sent to the underlying grid when called
  // This is useful for fill, align, etc.
  ..args,
) = {
  // See `utils.typ` for more info.
  let (parent-step, get-child) = counter-family("split-box-unique-counter-string")
  parent-step() // Place the parent counter once.
  // Keep track of each time the header is placed on a page.
  // Then check if we're at the first placement (for header) or the last (footer)
  // If not, we'll use the 'between' forms of the  border lines.
  let border-above = context {
    let header-count = get-child()
    header-count.step()
    context if header-count.get() == (1,) { border.above } else { border.btwn-above }
  }
  let border-below = context {
    let header-count = get-child()
    if header-count.get() == header-count.final() { border.below } else { border.btwn-below }
  }
  // Place the grid!
  grid(
    ..args.named(),
    columns: 3,
    border.left,
    grid.header(
      border-above,
      repeat: true,
    ),
    ..args.pos().map(cell),
    grid.footer(
      border-below,
      repeat: true,
    ),
    border.right,
  )
}

= Preamble
== License
Bose QuietComfort Ultra Headphones Bluetooth SPP Protocol Reverse‑engineered © 2026 by #link("https://docentcompany.com", "Krzysztof Kwiatkowski") is licensed under CC BY-NC-SA 4.0. To view a copy of this license, visit #link("https://creativecommons.org/licenses/by-nc-sa/4.0/", "https://creativecommons.org/licenses/by-nc-sa/4.0/")

== Motivation
#link("https://support.bose.com/s/product/bose-quietcomfort-ultra-headphones/01t8c00000QEpaxAAD?language=en_US")[Bose QuietComfort Ultra Headphones] can only be configured using a dedicated #link("https://www.bose.ca/en/apps/bose-app")[Bose App] available exclusively for mobile devices. This app requires iOS 17.0 or later or Android 13 and up (varies with device) #footnote[https://support.bose.com/s/article/quietcomfort-ultra-headphones-software-and-firmware-versions]. If you do not have a smartphone that meets the requirements, you will not be able to use the headphones to their full potential. There is also no certainty that the application will be available in the future. In order to secure the future of headphone users and increase headphones potential, the communication protocol has been reverse engineered.

== Method
The #link("https://www.bose.ca/en/apps/bose-app")[Bose App] has been installed on the Android phone. With #link("https://source.android.com/docs/core/connect/bluetooth/verifying_debugging#debugging-with-logs")[Bluetooth HCI snoop log] enabled, actions in the app were perfomed. Logs from the device located in _bugreport.zip/FS/data/log/bt/btsnoop_hci.log_ collected by #link("https://developer.android.com/studio/debug/bug-report?hl=pl#bugreportadb")[`adb bugreport`] command was opened in #link("https://www.wireshark.org/")[the Wireshark] software. The logs were analyzed manually. Python was used to test the queries:

```Python
import serial

ser = serial.Serial("COM4", 9600, timeout=1)
ser.write(bytes.fromhex("011b020101"))

data = ser.read(5) # Read 5 bytes
print(data.hex(" "), "".join(chr(b) if 32 <= b < 127 else "." for b in data))
```
Outgoing serial port can be found in the _More Bluetooth Settings -> COM Ports_.

Headphones firmware version: `1.6.7+g6ebabd2`.

#let command(body) = {
  table.cell(fill: green, [#body])
}

#let intention(body) = {
  table.cell(fill: blue, [#body])
}

#let payload(body) = {
  table.cell(fill: yellow, [#body])
}

#pagebreak()
= Protocol description
#section(2)[Request and response header]
#table(
  columns: 5,
  align: center,
  [*hex:*],
  command[XX XX],
  intention()[01 or 02 or 03 or 05 or 06 or 07],
  payload()[XX],
  [...],
  [*desc:*],
  [Command],
  table.cell(align: left)['Intentions':
    - *01* - Request sent by client to *get* informations.
    - *02* - Request sent by client to *set* some value in headphones.
    - *03* - Request sent by headphones as answer to the client request.
    - *04* - Request sent by headphones as answer to the client request. It means 'Command not found'.
    - *05* - Request sent by client when multiple requests as answer are expected (but single 06 can be returned). Cannot be replaced with 01 or 02.
    - *07* - Request sent by headphones as answer to the client request, that will be followed by another requests.
    - *06* - Request sent by headphones as answer to the client request, which means that this is the end of multiple answering requests.
  ],
  [Payload size],
  [Payload],
)

If command with intention `02` exists there is a there is a good chance that there is also a command with intent `01` with shared response.

== Volume
=== Get current volume
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[05], command[05], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 7,
  align: center,
  [], ..least-significant-bit-index(6),
  [*hex:*], command[05], command[05], intention[03], payload[02], [1f], [00 to 1f],
  [*desc:*], [], [], [], [], [], [Current volume],
) <get_current_volume_response>

=== Set volume
#section(4)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[05], command[05], intention[02], payload[01], [00 to 1f],
  [*desc:*], [], [], [], [], [Volume to set],
)

#section(4)[Response]
The same as in the #link("<get_current_volume_response>")[get current volume response].

== Modes
Each command starts with *1f*.

=== Get infromations about mode
#section(4)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[1f], command[06], intention[01], payload[01], [00 to 09],
  [*desc:*], [], [], [], [], [Mode index],
)

#section(4)[Response]
#split-box(
  // Block with stroke can be used instead but without dashed line on page break.
  [
    #table(
      columns: 11,
      align: center,
      [], ..least-significant-bit-index(51, end: 41),
      [*hex:*],
      command[1f],
      command[06],
      intention[03],
      payload[2f],
      [00 - 09],
      [00],
      [01],
      [00 or 01],
      [00],
      [00 or 01],
      [*desc:*],
      [],
      [],
      [],
      [],
      [mode index],
      [],
      [??],
      [if the mode is created by the user],
      [??],
      [if the mode is favourite],
    )
    #table(
      columns: 2,
      align: center,
      [], [41 - 7],
      [*desc:*],
      [Ascii encoded mode name. For example: 51 75 69 65 74 (00)... for "Quiet". "None" for not existing ones. Non-english characters are encoded incorrectly.
        TODO: Decode non-english chars.],
    )
    #table(
      columns: 7,
      align: center,
      [], ..least-significant-bit-index(6),
      [*hex:*], [00 or 02 or 0d ??], [00 - 0a], [00 or 01], [00 or 01 or 02], [00 or 01], [00 or 01],
      [*desc:*],
      [???],
      [ANC level 00 is max level, 0a disabled],
      [Is active sense enabled?],
      [Immersive voice mode (0 - 0ff, 1 - still, 2 - motion)],
      [The same as byte no. 43],
      [Is wind reduction enabled? If True, then ANC level is set to max (00)],
    )
  ],
) <mode_info>

=== Get list of modes
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[1f], command[01], intention[05], payload[00],
)

#section(4)[Response]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[1f], command[01], intention[07], payload[00],
)

#table(
  columns: 10,
  align: center,
  [], ..least-significant-bit-index(9),
  [*hex:*], command[1f], command[00], intention[03], payload[05], [31], [2e], [30], [2e], [30],
  [*ascii:*], [], [], [], [], [1], [.], [0], [.], [0],
)

#table(
  columns: 12,
  align: center,
  [], ..least-significant-bit-index(11),
  [*hex:*], command[1f], command[02], intention[03], payload[07], [03], [07], [00], [00], [00], [1f], [02],
)

#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[1f], command[03], intention[03], payload[01], [00 - 09 or ff],
  [*desc:*], [], [], [], [], [Curent mode index. If not existing mode (For e.g. quiet with immersive audio: ff).],
)

#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[1f], command[05], intention[03], payload[01], [00 or 01],
  [*desc:*], [], [], [], [], [Is remembering last mode when headphones are turned on on?],
)

\+ Repeated 10 times response in the same format as #link(<mode_info>)[the informations about mode].

#table(
  columns: 8,
  align: center,
  [], ..least-significant-bit-index(7),
  [*hex:*], command[1f], command[08], intention[03], payload[03], [0a], [03], [ff],
  [*desc:*], [], [], [], [], [??], [??], [??],
)

#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[1f], command[01], intention[06], payload[00],
)

=== Set mode
#section(4)[Request]
#table(
  columns: 7,
  align: center,
  [], ..least-significant-bit-index(6),
  [*hex:*], command[1f], command[03], intention[05], payload[02], [00 - 09], [01],
  [*desc:*], [], [], [], [], [Mode index], [???],
)

#section(4)[Response]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[1f], command[03], intention[06], payload[01], [00 - 09],
  [*desc:*], [], [], [], [], [Set mode index],
)

=== Create mode
_Updating mode_ is acomplished by creating a new one withg the same mode index.

#section(4)[Request]
#split-box(
  // Block with stroke can be used instead but without dashed line on page break.
  [
    #table(
      columns: 8,
      align: center,
      [], ..least-significant-bit-index(36, end: 29),
      [*hex:*], command[1f], command[06], intention[02], payload[27], [03 - 09], [00], [0e],
      [*desc:*], [], [], [], [], [mode index], [], [],
    )
    #table(
      columns: 2,
      align: center,
      [], [29 - 5],
      [*desc:*],
      [Ascii encoded mode name. For example: 52 65 6c 61 6b 73 (00)... for "Relaks". Non-english characters are encoded incorrectly.
        TODO: Decode non-english chars.],
    )
    #table(
      columns: 5,
      align: center,
      [], ..least-significant-bit-index(4),
      [*hex:*], [00 - 0a], [00], [00 or 01 or 02], [00 or 01],
      [*desc:*],
      [ANC level 00 is max level, 0a disabled],
      [??],
      [Immersive voice mode (0 - 0ff, 1 - still, 2 - motion)],
      [Enable wind reduction? If True, then ANC level should be set to max (00)],
    )
  ],
)

#section(4)[Response]
The same as in #link(<mode_info>)[the mode list response].

=== Get favourites
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[1f], command[08], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 8,
  align: center,
  [], ..least-significant-bit-index(7),
  [*hex:*], command[1f], command[08], intention[03], payload[03], [0a], [XX], [XX],
  [*desc:*],
  [],
  [],
  [],
  [],
  [],
  table.cell(
    colspan: 2,
  )[Bits are numerated from right. 1 means the mode with index corresponded to the bit number was set be favourite. 0 means set as not favourite.],
) <get_favourites_response>

=== Set favourites
#section(4)[Request]
#split-box(
  [
    #table(
      columns: 6,
      align: center,
      [], ..least-significant-bit-index(7, end: 2),
      [*hex:*], command[1f], command[08], intention[02], payload[03], [0a],
    )
    #table(
      columns: 3,
      align: center,
      [], ..least-significant-bit-index(2),
      [*bits:*], [0000 00XX], [XXXX XXXX],
      [*desc:*],
      table.cell(
        colspan: 2,
      )[Bits are numerated from right. 1 means the mode with index corresponded to the bit number will be favourite. 0 means not favourite.],
    )
  ],
)

#section(4)[Response]
The same as in the #link("<get_favourites_response>")[get favourites response].

=== Delete mode
#section(4)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[1f], command[09], intention[05], payload[01], [00 to 09],
  [*desc:*], [], [], [], [], [Index of the mode to delete],
)

#section(4)[Response]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[1f], command[09], intention[06], payload[00],
)

=== Get remember last mode
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[1f], command[05], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[1f], command[05], intention[03], payload[01], [00 or 01],
  [*desc:*], [], [], [], [], [If the last mode is remembered when the headphones are shut down.],
) <get_remember_last_mode_response>

=== Set remember last mode
#section(4)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[1f], command[05], intention[02], payload[01], [00 or 01],
  [*desc:*], [], [], [], [], [Should be last mode remembered when the headphones are shut down?],
)

#section(4)[Response]
The same as in the #link("<get_remember_last_mode_response>")[get remember last mode response].

== Immersion mode
=== Get current immersion mode
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[05], command[0f], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[05], command[0f], intention[03], payload[01], [00 or 01 or 02],
  [*desc:*], [], [], [], [], [Set immersive voice mode (0 - 0ff, 1 - still, 2 - motion)],
) <get_current_immersion_mode_response>

=== Set immersion mode
#section(4)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[05], command[0f], intention[02], payload[01], [00 or 01 or 02],
  [*desc:*], [], [], [], [], [Immersive voice mode to set (0 - 0ff, 1 - still, 2 - motion)],
)

#section(4)[Response]
The same as in the #link("<get_current_immersion_mode_response>")[get current immersion mode response].

=== Get current immersion mode calibration
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[05], command[11], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 6,
  align: center,
  // [], ..least-significant-bit-index(4),
  // 05 11 03 62 01 06 00 00 00 00 00 00 00 00 FE 08 AE FC 7F FC 11 5C 00 00 00 00 00 00 00 00 00 00 00 00 7F FF FF FF 00 00 00 00 00 00 00 00 00 00 00 00 7F FF FF FF FD E4 00 00 03 74 00 00 CB EA 00 00 74 DA 00 00 00 00 00 00 00 00 00 00 00 00 00 00 7F FF F7 9D 00 00 00 00 00 00 00 00 00 00 00 00 7F FF F7 9D
  [*hex:*], command[05], command[11], intention[03], payload[62], [...],
  [*desc:*], [], [], [], [], [Calibrated position in XYZ. TODO: Decode orientation representation.],
)

=== Calibrate immersion mode
#section(4)[Request]
The head should be pointed forward during calibration.
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[05], command[11], intention[05], payload[00],
)

#section(4)[Response]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[05], command[11], intention[07], payload[00],
)
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[05], command[11], intention[06], payload[01], [01 ??],
)

== Equalizer
=== Get equalizer settings
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[01], command[07], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 17,
  align: center,
  [], ..least-significant-bit-index(16),
  [*hex:*],
  command[01],
  command[07],
  intention[03],
  payload[0c],
  [f6],
  [0a],
  [00 - 0a or f6 - ff],
  [00],
  [f6],
  [0a],
  [00 - 0a or f6 - ff],
  [01],
  [f6],
  [0a],
  [00 - 0a or f6 - ff],
  [02],
  [*desc:*],
  [],
  [],
  [],
  [],
  [],
  [],
  [Level for low tones; 00 - 0a for positive levels and f6 - ff for negative levels],
  [],
  [],
  [],
  [Level for medium tones; 00 - 0a for positive levels and f6 - ff for negative levels],
  [],
  [],
  [],
  [Level for high tones; 00 - 0a for positive levels and f6 - ff for negative levels],
  [],
) <get_equalizer_settings_response>

=== Set equalizer settings
#section(4)[Request]
#table(
  columns: 7,
  align: center,
  [], ..least-significant-bit-index(6),
  [*hex:*], command[01], command[07], intention[02], payload[02], [00 - 0a or f6 - ff], [00 or 01 or 02],
  [*desc:*],
  [],
  [],
  [],
  [],
  [Value to set: 00 - 0a for positive ones and f6 - ff for negative ones],
  [Value for which tones should be set: 0 - low, 1 - medium - 2 - high],
)

#section(4)[Response]
The same as for the #link("<get_equalizer_settings_response>")[get equalizer settings response].

== Shortcut
=== Get current shortcut
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[01], command[09], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 12,
  align: center,
  [], ..least-significant-bit-index(11),
  [*hex:*],
  command[01],
  command[09],
  intention[03],
  payload[07],
  [80],
  [09],
  [0e or 03 or 13 or 01 or 10],
  [00],
  [09],
  [40],
  [0a],
  [*desc:*],
  [],
  [],
  [],
  [],
  [],
  [],
  table.cell(align: left, [
    - 0e - disabled
    - 03 - battery level
    - 13 - immersion mode
    - 01 - voice assistant
    - 10 - spotify shortcut
  ]),
  [],
  [],
  [],
  [],
) <get_current_shortcut_response>

=== Set shortcut
#section(4)[Request]
#table(
  columns: 8,
  align: center,
  [], ..least-significant-bit-index(7),
  [*hex:*], command[01], command[09], intention[02], payload[03], [80], [09], [0e or 03 or 13 or 01 or 10],
  [*desc:*],
  [],
  [],
  [],
  [],
  [],
  [],
  table.cell(align: left, [
    - 0e - disabled
    - 03 - battery level
    - 13 - immersion mode
    - 01 - voice assistant
    - 10 - spotify shortcut
  ]),
)

#section(4)[Response]
The same as for the #link("<get_current_shortcut_response>")[get current shortcut response].

== Settings
=== Device name
==== Get device name
#section(5)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[01], command[02], intention[01], payload[00],
)

#section(5)[Response]
#table(
  columns: 7,
  align: center,
  [*hex:*], command[01], command[02], intention[03], payload[XX], [00], [...],
  [*desc:*], [], [], [], [], [], [Ascii encoded device name],
) <get_device_name_response>

==== Set device name
#section(5)[Request]
#table(
  columns: 6,
  align: center,
  [*hex:*], command[01], command[02], intention[02], payload[XX], [...],
  [*desc:*], [], [], [], [], [Ascii encoded string to be set as a device name],
)

#section(4)[Response]
The same as the #link("<get_device_name_response>")[get device name response].

=== Level of microphone monitoring during calls
==== Get current level
#section(5)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[01], command[0b], intention[01], payload[00],
)

#section(5)[Response]
#table(
  columns: 8,
  align: center,
  [], ..least-significant-bit-index(7),
  [*hex:*], command[01], command[0b], intention[03], payload[03], [01], [00 or 01 or 02 or 03], [0f],
  [*desc:*],
  [],
  [],
  [],
  [],
  [],
  table.cell(align: left, [
    - 0 - off
    - 1 - low
    - 2 - medium
    - 3 - high
  ]),
) <get_level_of_microphone_monitoring_response>

==== Set level
#section(5)[Request]
#table(
  columns: 7,
  align: center,
  [], ..least-significant-bit-index(6),
  [*hex:*], command[01], command[0b], intention[02], payload[02], [01], [00 or 01 or 02 or 03],
  [*desc:*],
  [],
  [],
  [],
  [],
  [],
  table.cell(align: left, [
    - 0 - off
    - 1 - low
    - 2 - medium
    - 3 - high
  ]),
)

#section(5)[Response]
The same as for the #link("<get_level_of_microphone_monitoring_response>")[get level of microphone monitoring during calls response].

=== Auto off time
==== Get current time settings
#section(5)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[01], command[04], intention[01], payload[00],
)

#section(5)[Response]
#table(
  columns: 8,
  align: center,
  [], ..least-significant-bit-index(7),
  [*hex:*], command[01], command[04], intention[03], payload[03], [XX], [00], [XX],
  [*desc:*],
  [],
  [],
  [],
  [],
  table.cell(
    colspan: 3,
    align: left,
    [
      - 00 00 00 - never
      - 05 00 00 - 5 minutes
      - 14 00 00 - 20 minutes
      - 28 00 00 - 40 minutes
      - 3c 00 00 - 1 hour
      - b4 00 00 - 3 hours
      - a0 00 05 - 24 hours
    ],
  ),
) <get_auto_off_time_response>

==== Set auto off time
#section(5)[Request]
#table(
  columns: 6,
  align: center,
  [*hex:*], command[01], command[04], intention[02], payload[01 or 02], [XX or XX XX],
  [*desc:*],
  [],
  [],
  [],
  [],
  table.cell(
    align: left,
    [
      - 00 - never
      - 05 - 5 minutes
      - 14 - 20 minutes
      - 28 - 40 minutes
      - 3c - 1 hour
      - b4 - 3 hours
      - a0 05 - 24 hours
    ],
  ),
)

#section(5)[Response]
The same as in #link(<get_auto_off_time_response>)[response of get auto off time].

=== Auto stopping music when headphones are not on the head
==== Get current setting
#section(5)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[01], command[18], intention[01], payload[00],
)

#section(5)[Response]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[01], command[18], intention[03], payload[01], [00 or 01],
  [*desc:*], [], [], [], [], [Is music stopped when headphones are not on head? 1 - yes, 0 - no],
) <get_auto_stopping_music_response>

==== Set auto stopping music when headphones are not on the head
#section(5)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[01], command[18], intention[02], payload[01], [00 or 01],
  [*desc:*], [], [], [], [], [Should music be stopped when headphones are not on head? 1 - yes, 0 - no],
)

#section(5)[Response]
The same as for the #link("<get_auto_stopping_music_response>")[get auto stopping music when headphones are not on the head response].

=== Auto call answering when headphones are put on head
==== Get current setting
#section(5)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[01], command[1b], intention[01], payload[00],
)

#section(5)[Response]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[01], command[1b], intention[03], payload[01], [00 or 01],
  [*desc:*], [], [], [], [], [Are calls auto answered when headphones are put on head? 1 - yes, 0 - no],
) <get_auto_call_answering_response>

==== Set auto call answering when headphones are put on head
#section(5)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[01], command[1b], intention[02], payload[01], [00 or 01],
  [*desc:*], [], [], [], [], [Should calls be auto answered when headphones are put on head? 1 - yes, 0 - no],
)

#section(5)[Response]
The same as for the #link("<get_auto_call_answering_response>")[get auto call answering when headphones are put on head response].

=== Voice prompts
==== Get options
#section(5)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[01], command[03], intention[01], payload[00],
)

#section(5)[Response]
#split-box(
  [
    #table(
      columns: 5,
      align: center,
      [], ..least-significant-bit-index(11, end: 7),
      [*hex:*], command[1f], command[03], intention[03], payload[07],
    )
    #table(
      columns: 5,
      align: center,
      [],
      table.cell(colspan: 4, ..least-significant-bit-index(7, end: 6)),
      [*bits:*], [0], [0 or 1], [0 or 1], [0 0000],
      [*desc:*],
      [],
      [Is current language a default one (english)? 0 - no, 1 - yes],
      [Are voice prompts about connected devices enabled? 0 - no, 1 - yes],
      table.cell(align: left, [Set language of voice prompts.
        - 0 0001 - English
        - 0 0010 - French
        - 0 0011 - Italian
        - 0 0100 - German
        - 0 0110 - Spanish
        - 0 1000 - Chinese
        - 0 1111 - Guangdong dialect; Cantonese
        - 1 0000 - Japanese
      ]),
    )
    #table(
      columns: 7,
      align: center,
      [], ..least-significant-bit-index(6),
      [*hex:*], [00], [01], [81], [e5], [01], [00 or 01],
      [*desc:*], [], [], [], [], [], [Is battery level info enabled when headphones are turn on? 0 - no, 1 - yes],
    )
  ],
) <get_voice_prompts_response>

==== Set options
#section(5)[Request]
#split-box(
  [
    #table(
      columns: 5,
      align: center,
      [], ..least-significant-bit-index(6, end: 2),
      [*hex:*], command[01], command[03], intention[02], payload[02],
    )
    #table(
      columns: 5,
      align: center,
      [],
      table.cell(colspan: 4, ..least-significant-bit-index(2, end: 1)),
      [*bits:*], [0], [0], [0 or 1], [0 0000],
      [*desc:*], [], [], [Should voice prompts about connected devices be enabled? 0 - no, 1 - yes],
      table.cell(align: left, [Set language of voice prompts.
        - 0 0001 - english
        - 0 0010 - french
        - 0 0011 - italian
        - 0 0100 - german
        - 0 0110 - spanish
        - 0 1000 - Chinese
        - 0 1111 - Guangdong dialect; Cantonese
        - 1 0000 - Japanese
      ]),
    )
    #table(
      columns: 2,
      align: center,
      [], ..least-significant-bit-index(1),
      [*hex:*], [00 or 01],
      [*desc:*], [Should battery level info be enabled when headphones are turn on? 0 - no, 1 - yes],
    )
  ],
)

#section(5)[Response]
The same as in #link(<get_voice_prompts_response>)[response of get voice prompts options].

== Bluetooth
=== Multipoint connections
==== Are enabled?
#section(5)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[01], command[0a], intention[01], payload[00],
)

#section(5)[Response]
#split-box(
  [
    #table(
      columns: 5,
      align: center,
      [], ..least-significant-bit-index(5, end: 1),
      [*hex:*], command[01], command[0a], intention[03], payload[01],
    )
    #table(
      columns: 9,
      align: center,
      [],
      table.cell(colspan: 8, ..least-significant-bit-index(1)),
      [*bits:*], [0], [0], [0], [0], [0], [1], [1], [0 or 1],
      [*desc:*], [], [], [], [], [], [], [], [Are multipoint connections enabled? 0 - no, 1 - yes],
    )
  ],
) <are_multipoint_connections_enabled_response>

==== Turn on and off multipoint connection
#section(5)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[01], command[0a], intention[02], payload[01], [00 or 01],
  [*desc:*], [], [], [], [], [Should multipoint connections be enabled? 0 - no, 1 - yes],
)

#section(5)[Response]
Teh same as for the #link("<are_multipoint_connections_enabled_response>")[are multipoint connections enabled response].

=== Get paired devices identificator
#section(4)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[04], command[04], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 18,
  align: center,
  [], ..least-significant-bit-index(17),
  [*hex:*],
  command[04],
  command[04],
  intention[03],
  payload[0D],
  [03],
  [E0],
  [0A],
  [F6],
  [73],
  [B1],
  [A2],
  [64],
  [89],
  [F1],
  [26],
  [8E],
  [8E],
  [*desc:*], [], [], [], [], [],
  table.cell(colspan: 6)[second paired device identificator (?)],
  table.cell(colspan: 6)[First paired device identificator (?)],
)

=== Get paired device informations
#section(4)[Request]
#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(10, end: 6), [...],
  [*hex:*], command[04], command[05], intention[01], payload[06], [...],
  [*desc:*], [], [], [], [], [Paired device identificator],
)

#section(4)[Response]
#table(
  columns: 15,
  align: center,
  [*hex:*],
  command[04],
  command[05],
  intention[03],
  payload[XX],
  [64],
  [89],
  [F1],
  [26],
  [8e],
  [8e],
  [00 or 01 or 03??],
  [02],
  [03],
  [...],

  [*desc:*],
  [],
  [],
  [],
  [Payload size],
  [?],
  [?],
  [?],
  [?],
  [?],
  [?],
  [Changes if device is connected or disconnected],
  [?],
  [?],
  [Paired device name],
)

== Informations
=== Get current playing media informations
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[05], command[06], intention[05], payload[00],
)

#section(4)[Response]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[05], command[06], intention[07], payload[00],
)

#table(
  columns: 7,
  align: center,
  [*hex:*], command[05], command[06], intention[03], payload[XX], [00], [...],
  [*desc:*], [], [], [], [], [], [Ascii encoded current playing media title],
)

#table(
  columns: 7,
  align: center,
  [*hex:*], command[05], command[06], intention[03], payload[XX], [01], [...],
  [*desc:*], [], [], [], [], [], [Ascii encoded current playing media artist],
)

#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[05], command[06], intention[06], payload[00],
)


=== Get headphones firmware version
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[00], command[05], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 6,
  align: center,
  [*hex:*], command[00], command[05], intention[03], payload[XX], [...],
  [*desc:*], [], [], [], [], [Ascii encoded current firmware version. For e.g. '1.6.7+g6ebabd2'.],
)

=== Get headphones serial number
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[00], command[07], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 6,
  align: center,
  [*hex:*], command[00], command[07], intention[03], payload[XX], [...],
  [*desc:*], [], [], [], [], [Ascii encoded serial number.],
)

=== Get headphones product identification number (GUID)
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  [*hex:*], command[00], command[0C], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 6,
  align: center,
  [*hex:*], command[00], command[0C], intention[03], payload[10], [...],
  [*desc:*], [], [], [], [], [GUID. NOT ascii encoded.],
)

=== Get ???? version
#section(4)[Request]
#table(
  columns: 5,
  align: center,
  [], ..least-significant-bit-index(4),
  // 00 0C 01 00 00 05 01 00
  [*hex:*], command[00], command[01], intention[01], payload[00],
)

#section(4)[Response]
#table(
  columns: 6,
  align: center,
  [*hex:*], command[02], command[00], intention[03], payload[XX], [...],
  [*desc:*], [], [], [], [], [Ascii encoded version. For e.g.: '1.2.0'],
)

=== Get ???? version
Four possible requests with four possible responses. All returned values expect the first one and the last one is the same for all requests.
#section(4)[Request]
#columns(4)[
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[02], command[01], intention[05], payload[00],
  )
  #colbreak()
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[01], command[01], intention[05], payload[00],
  )
  #colbreak()
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[00], command[04], intention[05], payload[00],
  )
  #colbreak()
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    // 00 0C 01 00 00 05 01 00
    [*hex:*], command[05], command[02], intention[05], payload[00],
  )
]

#section(4)[Response]
#columns(4)[
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[02], command[01], intention[07], payload[00],
  )
  #colbreak()
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[01], command[01], intention[07], payload[00],
  )
  #colbreak()
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[00], command[04], intention[07], payload[00],
  )
  #colbreak()
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[05], command[02], intention[07], payload[00],
  )
]

#table(
  columns: 6,
  align: center,
  [*hex:*], command[02], command[00], intention[03], payload[XX], [...],
  [*desc:*], [], [], [], [], [Ascii encoded version. For e.g.: '1.1.0'],
)

#table(
  columns: 9,
  align: center,
  [], ..least-significant-bit-index(8),
  [*hex:*], command[02], command[02], intention[03], payload[04], [28], [FF], [FF], [00],
  [*desc: ????*], [], [], [], [], [],
)

#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[02], command[05], intention[03], payload[01], [00],
  [*desc: ????*], [], [], [], [], [],
)

#table(
  columns: 9,
  align: center,
  [], ..least-significant-bit-index(8),
  [*hex:*], command[02], command[0F], intention[03], payload[04], [00], [60], [00], [00],
  [*desc: ????*], [], [], [], [], [],
)

#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[02], command[10], intention[03], payload[01], [01],
  [*desc: ????*], [], [], [], [], [],
)

#table(
  columns: 6,
  align: center,
  [], ..least-significant-bit-index(5),
  [*hex:*], command[02], command[11], intention[03], payload[01], [01],
  [*desc: ????*], [], [], [], [], [],
)

#columns(4)[
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[02], command[01], intention[06], payload[00],
  )
  #colbreak()
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[01], command[01], intention[06], payload[00],
  )
  #colbreak()
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[00], command[04], intention[06], payload[00],
  )
  #colbreak()
  #table(
    columns: 5,
    align: center,
    [], ..least-significant-bit-index(4),
    [*hex:*], command[05], command[02], intention[06], payload[00],
  )
]

#pagebreak()
#heading(numbering: none)[Appendix]
#heading(level: 2, numbering: none)[Advanced debugging Python code]
#raw(read("send_and_read.py"), lang: "Python")

// #import "@preview/rivet:0.3.0": schema

// #box(width: 5cm)[
//   #schema.render(schema.load(yaml("./get.yaml")))
// ]

// #schema.render(schema.load(yaml("./return.yaml")))


