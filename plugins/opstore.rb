
class OpStore < Btmonad::Bot
  def on_join(m)
    nick = m.prefix.split('!')[0]
    if nick != Btmonad::Config["nick"]
      @post.call "MODE", m[0], "+o", nick
    end
  end
end

