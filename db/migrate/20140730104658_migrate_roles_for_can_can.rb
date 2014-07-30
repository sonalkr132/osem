class MigrateRolesForCanCan < ActiveRecord::Migration

  def up
    # Store the number of existing roles
    old_roles = Role.count

    Role.all.each do |role|
      role.users.each do |user|
        Conference.all.each do |conference|
          if role.name == 'Admin' || role.name == 'Organizer'
            user.add_role :organizer, conference
          else
            user.add_role role.name.parameterize.underscore.to_sym, conference
          end
        end
      end
    end

    # Delete old roles
    Role.first(old_roles).each do |role|
      role.destroy
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration.new('Cannot reverse migration. Deleted events cannot be re-created')
  end
end
