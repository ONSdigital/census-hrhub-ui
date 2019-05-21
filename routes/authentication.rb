auth_logger = Syslog::Logger.new(PROGRAM, Syslog::LOG_AUTHPRIV)

helpers do
  def user_role
    session[:user].groups.join(',')
  end
end

get '/signin/?' do
  erb :signin, layout: :layout, locals: { title: 'Sign In' }
end

post '/signin/?' do
  RestClient::Request.execute(method: :get,
                              url: "http://#{CENSUS_FSDR_HOST}:#{CENSUS_FSDR_PORT}/userAuth?password=#{params[:password]}&username=#{params[:username]}") do |userauth_response, _request, _result, &_block|
    results = JSON.parse(userauth_response) unless userauth_response.code == 404
    if !results.nil?
      session.clear
      session[:valid_token] = true
      session[:user] = params[:username]
      session[:role] = results['userRole']
      redirect '/'
    else
      flash[:notice] = 'You could not be signed in. Did you enter the correct credentials?'
      redirect '/signin'
    end
  end
end

get '/signout' do
  session.clear
  session[:valid_token] = nil
  redirect '/signin'
end
