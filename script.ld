SECTIONS
{
  . = 0x0;
  .text : {
    *(.text)
  }
  . = ALIGN(0x10);
  .data : {
    *(.data)
  }
}

