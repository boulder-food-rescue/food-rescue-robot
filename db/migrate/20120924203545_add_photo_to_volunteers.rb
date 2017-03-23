class AddPhotoToVolunteers < ActiveRecord::Migration
  def up
    add_attachment :volunteers, :photo
  end

  def down
    remove_attachment :volunteers, :photo
  end
end
