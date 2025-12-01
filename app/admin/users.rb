ActiveAdmin.register User do
  menu priority: 2, label: "Users"

  permit_params :email, :password, :password_confirmation, :name, :role, :phone_number, :country_code

  # Filters
  filter :email
  filter :name
  filter :phone_number
  filter :role, as: :select, collection: User.roles.keys
  filter :created_at

  # Index page
  index do
    selectable_column
    id_column
    column :name
    column :email
    column :phone_number
    column :role do |user|
      status_tag user.role, class: user.super_admin? ? "yes" : (user.admin? ? "warning" : "no")
    end
    column :provider do |user|
      user.provider.present? ? status_tag(user.provider, class: "ok") : "-"
    end
    column :created_at
    actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :name
      row :email
      row :phone_number
      row :full_phone_number
      row :role do |user|
        status_tag user.role, class: user.super_admin? ? "yes" : (user.admin? ? "warning" : "no")
      end
      row :provider
      row :uid
      row :avatar_url do |user|
        user.avatar_url.present? ? image_tag(user.avatar_url, width: 50) : "-"
      end
      row :created_at
      row :updated_at
    end
  end

  # Form
  form do |f|
    f.inputs "User Details" do
      f.input :name
      f.input :email
      f.input :phone_number
      f.input :country_code, as: :select, collection: [ "+91", "+1", "+44", "+61" ]
      f.input :password, hint: "Leave blank to keep current password"
      f.input :password_confirmation

      # Only super_admin can change roles
      if current_user.super_admin?
        f.input :role, as: :select, collection: User.roles.keys
      end
    end
    f.actions
  end

  # Custom action to promote to admin
  member_action :promote_to_admin, method: :put do
    resource.update!(role: :admin)
    redirect_to admin_user_path(resource), notice: "User promoted to Admin!"
  end

  member_action :demote_to_user, method: :put do
    resource.update!(role: :user)
    redirect_to admin_user_path(resource), notice: "User demoted to regular user."
  end

  action_item :promote, only: :show do
    if current_user.super_admin? && resource.user?
      link_to "Promote to Admin", promote_to_admin_admin_user_path(resource), method: :put,
              data: { confirm: "Promote #{resource.name} to Admin?" }
    end
  end

  action_item :demote, only: :show do
    if current_user.super_admin? && resource.admin? && resource != current_user
      link_to "Demote to User", demote_to_user_admin_user_path(resource), method: :put,
              data: { confirm: "Demote #{resource.name} to regular user?" }
    end
  end

  # Controller customizations
  controller do
    def update
      if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
      super
    end
  end
end
