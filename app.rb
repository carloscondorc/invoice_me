require 'sinatra'
require './lib/cuentica'

add_invoice_action = Cuentica::AddInvoice.new
autenticate_a_user = Cuentica::AuthenticateAUser.new

enable :sessions

def is_authenticated!
  redirect '/login' unless session[:current_cif]
end

get '/login' do
  erb :login, :locals => {:errors => nil}
end

post '/login' do
  user = autenticate_a_user.run(params[:user], params[:password])
  if user
    session[:current_cif] = user.cif
    redirect '/'
  else
    status 422
    erb :login, :locals => {:errors => ['Invalid User']}
  end
end

get '/' do
  is_authenticated!

  erb :index, :locals => {:errors => nil}
end

post '/' do
  is_authenticated!

  cif = session[:current_cif]

  if params[:file]
    filename = params[:file][:filename]
    file = params[:file][:tempfile]

    params[:attachment] = {
      filename: filename,
      data: file.read
    }
  end

  expense_lines = []
  if params[:description]
    params[:description].each_with_index do |description, index|
      expense_line = {}
      expense_line[:description] = description
      expense_line[:base] = params[:base][index].to_f
      expense_line[:vat] = params[:vat][index].to_i
      expense_line[:retention] = params[:retention][index].to_i
      expense_lines.push(expense_line)
    end
  end
  params[:expense_lines] = expense_lines

  begin
    invoice = add_invoice_action.run(cif, params)
    redirect '/'
  rescue Cuentica::InvalidInvoiceError => e
    status 422
    erb :index, :locals => {:errors => e.messages}
  end
end
