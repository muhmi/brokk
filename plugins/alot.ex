defmodule Brokk.Plugins.Alot do

  use Brokk.Plugin

  @images [
    "http://4.bp.blogspot.com/_D_Z-D2tzi14/S8TRIo4br3I/AAAAAAAACv4/Zh7_GcMlRKo/s400/ALOT.png",
    "http://3.bp.blogspot.com/_D_Z-D2tzi14/S8TTPQCPA6I/AAAAAAAACwA/ZHZH-Bi8OmI/s1600/ALOT2.png",
    "http://2.bp.blogspot.com/_D_Z-D2tzi14/S8TiTtIFjpI/AAAAAAAACxQ/HXLdiZZ0goU/s320/ALOT14.png",
    "http://fc02.deviantart.net/fs70/f/2010/210/1/9/Alot_by_chrispygraphics.jpg"
  ]

  def on_message(_from, {:text, message}) do
    cond do
      message =~ ~r/(^|\W)alot(\z|\W|$)/i ->
        {:reply, Enum.random(@images)}
      true ->
        :noreply
    end
  end

end