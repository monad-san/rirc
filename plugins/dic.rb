require 'rexml/document'
require 'open-uri'

class DicBot < Btmonad::Bot
  def ch_privmsg(m)
    if m =~ /d\s+(.+)/ then
      word = $1.toutf8
      if word =~ /^[a-zA-Z]+$/ then
        surl = "http://public.dejizo.jp/NetDicV09.asmx/SearchDicItemLite" \
          "?Dic=EJdict" \
          "&Word=#{word}" \
          "&Scope=HEADWORD" \
          "&Match=EXACT" \
          "&Merge=AND" \
          "&Prof=XHTML" \
          "&PageSize=1" \
          "&PageIndex=0"
        notice "Searching \"#{word}\" ..."
        rdoc = REXML::Document.new(open(surl))

        if rdoc.elements['SearchDicItemResult/TotalHitCount'].text.to_i > 0 then
          iid = rdoc.elements['SearchDicItemResult/TitleList/DicItemTitle/ItemID'].text
          gurl = "http://public.dejizo.jp/NetDicV09.asmx/GetDicItemLite" \
            "?Dic=EJdict" \
            "&Item=#{iid}" \
            "&Loc=" \
            "&Prof=XHTML"
          gdoc = REXML::Document.new(open(gurl))

          result = gdoc.elements['GetDicItemResult/Body/div[@class="NetDicBody"]/div'].text
          if result.length > 300 then
            result = result[0..290] + "..."
          end
         privmsg result.tojis 
        else
          notice "The word was not found."
        end
      else
        surl = "http://public.dejizo.jp/NetDicV09.asmx/SearchDicItemLite" \
          "?Dic=EdictJE" \
          "&Word=#{URI.encode(word)}" \
          "&Scope=HEADWORD" \
          "&Match=EXACT" \
          "&Merge=AND" \
          "&Prof=XHTML" \
          "&PageSize=1" \
          "&PageIndex=0"
        notice "Searching \"#{word}\" ...".tojis
        rdoc = REXML::Document.new(open(surl))

        if rdoc.elements['SearchDicItemResult/TotalHitCount'].text.to_i > 0 then
          iid = rdoc.elements['SearchDicItemResult/TitleList/DicItemTitle/ItemID'].text
          gurl = "http://public.dejizo.jp/NetDicV09.asmx/GetDicItemLite" \
            "?Dic=EdictJE" \
            "&Item=#{iid}" \
            "&Loc=" \
            "&Prof=XHTML"
          gdoc = REXML::Document.new(open(gurl))

          ga = []
          gdoc.elements.each('GetDicItemResult/Body/div[@class="NetDicBody"]/div/div') do |elem|
            if elem.text =~ /^(\s*)(.+?)(\s*)$/ then
              ga.push $2
            end
          end
          privmsg ga.join(" / ").tojis
        else
          notice "The word was not found."
        end
      end
    end
  end
end

