xml.instruct! :xml, :version=>"1.0" 
xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do |feed|
  feed.title @title
  feed.link :type => 'text/html', :rel => 'alternate',
    :href => full_resource(:comments)

  @comments.each do |comment|
    feed.entry do |entry|
      entry.id comment.id
      entry.title "Comment to post#%s" % comment.post.id
      entry.content comment.body, :type => 'text'
      #entry.issued comment.created_at
      #entry.modified comment.updated_at
      entry.link :type => "text/html", :rel => "alternate",
        :href => full_resource(comment)
      #entry.author do |author|
      #  author.name comment.user.login
      #end
    end
  end
end
