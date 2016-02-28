require 'spec_helper'

describe ConferenceRegistrationsController, type: :controller do
  let(:conference) { create(:conference) }
  let(:conference_with_open_registration) { create(:conference, registration_period: open_registration_period) }
  let(:open_registration_period) { create(:registration_period, start_date: Date.current - 6.days) }
  let(:user) { create(:user) }

  context 'user is signed in' do
    before { sign_in(user) }

    describe 'GET #new' do
      context 'user is registered to conference' do
        before do
          create(:registration, user: user, conference: conference_with_open_registration)
          get :new, conference_id: conference_with_open_registration.short_title
        end

        it 'redirects to edit registration page' do
          expect(response).to redirect_to edit_conference_conference_registrations_path(conference_with_open_registration.short_title)
        end
      end

      context 'ichain is enabled and user is not signed in' do
        before do
          CONFIG['authentication']['ichain']['enabled'] = true
          sign_out user
          get :new, conference_id: conference_with_open_registration.short_title
        end

        after { CONFIG['authentication']['ichain']['enabled'] = false }

        it 'redirects to root path' do
          expect(response).to redirect_to root_path
        end
      end

      context 'registration limit has reached' do
        before do
          conference_with_open_registration.update_attributes(registration_limit: 1)
          create(:registration, conference: conference_with_open_registration)
          get :new, conference_id: conference_with_open_registration.short_title
        end

        it 'redirects to root path' do
          expect(response).to redirect_to root_path
        end

        it 'shows error in flash message' do
          expect(flash[:alert]).to match "Sorry, registration limit exceeded for #{conference_with_open_registration.title}"
        end
      end

      context 'successful request' do
        before do
          get :new, conference_id: conference_with_open_registration.short_title
        end

        it 'assigns registration and user variables' do
          expect(assigns(:registration)).to be_instance_of(Registration)
          expect(assigns(:user)).to be_instance_of(User)
        end

        it 'renders the new template' do
          expect(response).to render_template('new')
        end
      end
    end

    describe 'GET #show' do
      before do
        @registration = create(:registration, conference: conference_with_open_registration, user: user)
        @ticket = create(:ticket, conference: conference_with_open_registration)
        @purchased_ticket = create(:ticket_purchase, conference: conference_with_open_registration, user: user, ticket: @ticket)
        get :show, conference_id: conference_with_open_registration.short_title
      end

      it 'renders the show template' do
        expect(response).to render_template('show')
      end

      it 'assigns workshops, total_price and tickets variables' do
        expect(assigns(:workshops)).to eq @registration.workshops
        expect(assigns(:total_price)).to eq @ticket.price * @purchased_ticket.quantity
        expect(assigns(:tickets)).to match_array [@purchased_ticket]
      end
    end

    describe 'GET #edit' do
      before do
        create(:registration, conference: conference_with_open_registration, user: user)
        get :edit, conference_id: conference_with_open_registration.short_title
      end

      it 'renders the edit template' do
        expect(response).to render_template('edit')
      end
    end

    describe 'POST #create' do
      context 'user is not signed' do
        before do
          sign_out user
          post :create, user: attributes_for(:user),
                        registration: attributes_for(:registration),
                        conference_id: conference_with_open_registration.short_title
        end

        it 'assigns user variable' do
          expect(assigns(:user)).not_to be_nil
        end

        it 'signs in registration user' do
          expect(controller.current_user).not_to be_nil
        end

        it 'shows success message in flash notice' do
          expect(flash[:notice]).to match('You are now registered and will be receiving E-Mail notifications.')
        end

        it 'redirects to registration show path' do
          expect(response).to redirect_to conference_conference_registrations_path(conference_with_open_registration.short_title)
        end

        it 'creates a new registration' do
          expect(Registration.count).to eq 1
        end
      end

      context 'user is signed in' do
        before do
          post :create, registration: attributes_for(:registration),
                        conference_id: conference_with_open_registration.short_title
        end

        it 'assigns user variable' do
          expect(assigns(:user)).to eq user
        end
      end

      context "tickets are avilable and user hasn't bought any" do
        before do
          create(:ticket, conference: conference_with_open_registration)
          post :create, registration: attributes_for(:registration),
                        conference_id: conference_with_open_registration.short_title
        end

        it 'redirects to conference tickets path' do
          expect(response).to redirect_to conference_tickets_path(conference_with_open_registration.short_title)
        end
      end

      context 'registration save fails' do
        before do
          allow_any_instance_of(Registration).to receive(:save).and_return(false)
          post :create, registration: attributes_for(:registration),
                        conference_id: conference_with_open_registration.short_title
        end

        it 'renders the new template' do
          expect(response).to render_template('new')
        end

        it 'does not create registration' do
          expect(Registration.count).to eq 0
        end
      end
    end

    describe 'PATCH #update' do
      before do
        @registration = create(:registration, conference: conference_with_open_registration, user: user)
      end

      context 'updates successfully' do
        before do
          patch :update, registration: attributes_for(:registration, arrival: Date.new(2014, 04, 29)),
                         conference_id: conference_with_open_registration.short_title
        end

        it 'redirects to registration show path' do
          expect(response).to redirect_to conference_conference_registrations_path(conference_with_open_registration.short_title)
        end

        it 'shows success message in flash notice' do
          expect(flash[:notice]).to match('Registration was successfully updated.')
        end

        it 'updates the registration' do
          @registration.reload
          expect(@registration.arrival).to eq Date.new(2014, 04, 29)
        end
      end

      context 'update fails' do
        before do
          allow_any_instance_of(Registration).to receive(:save).and_return(false)
          patch :update, registration: attributes_for(:registration, arrival: Date.new(2014, 04, 29)),
                         conference_id: conference_with_open_registration.short_title
        end

        it 'renders edit template' do
          expect(response).to render_template('edit')
        end

        it 'shows error in flash message' do
          expect(flash[:error]).to include 'Could not update your registration'
        end
      end
    end

    describe 'DELETE #destroy' do
      before do
        @registration = create(:registration, conference: conference_with_open_registration, user: user)
      end

      context 'deletes successfully' do
        before do
          delete :destroy, conference_id: conference_with_open_registration.short_title
        end

        it 'redirects to root path' do
          expect(response).to redirect_to root_path
        end

        it 'shows success message in flash notice' do
          expect(flash[:notice]).to match("You are not registered for #{conference_with_open_registration.title} anymore!")
        end

        it 'deletes the registration' do
          expect(Registration.count).to eq 0
        end
      end

      context 'delete fails' do
        before do
          allow_any_instance_of(Registration).to receive(:destroy).and_return(false)
          delete :destroy, conference_id: conference_with_open_registration.short_title
        end

        it 'redirects to registration show path' do
          expect(response).to redirect_to conference_conference_registrations_path(conference_with_open_registration.short_title)
        end

        it 'shows error in flash message' do
          expect(flash[:error]).to include 'Could not delete your registration'
        end

        it 'does not delete the registration' do
          expect(Registration.last).to eq @registration
        end
      end
    end
  end
end
