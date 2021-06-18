defmodule BlogWeb.Router do
  use BlogWeb, :router

  import BlogWeb.AuthorAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BlogWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_author
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BlogWeb do
    pipe_through :browser

    live "/", PostsLive, :index
    get "/author/:author_id", AuthorPostsController, :index
    get "/posts/:post_id", AuthorPostsController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", BlogWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: BlogWeb.Telemetry
    end
  end

  ## Authentication routes

  scope "/", BlogWeb do
    pipe_through [:browser, :redirect_if_author_is_authenticated]

    get "/authors/register", AuthorRegistrationController, :new
    post "/authors/register", AuthorRegistrationController, :create
    get "/authors/log_in", AuthorSessionController, :new
    post "/authors/log_in", AuthorSessionController, :create
    get "/authors/reset_password", AuthorResetPasswordController, :new
    post "/authors/reset_password", AuthorResetPasswordController, :create
    get "/authors/reset_password/:token", AuthorResetPasswordController, :edit
    put "/authors/reset_password/:token", AuthorResetPasswordController, :update
  end

  scope "/", BlogWeb do
    pipe_through [:browser, :require_authenticated_author]

    get "/authors/settings", AuthorSettingsController, :edit
    put "/authors/settings", AuthorSettingsController, :update
    get "/authors/settings/confirm_email/:token", AuthorSettingsController, :confirm_email
  end

  scope "/post", BlogWeb do
    pipe_through [:browser, :require_authenticated_author]
    get "/new", AuthorPostsController, :new
    post "/new", AuthorPostsController, :create
    get "/edit/:post_id", AuthorPostsController, :edit
    post "/edit/:post_id", AuthorPostsController, :update
    delete "/edit/:post_id", AuthorPostsController, :delete
  end

  scope "/", BlogWeb do
    pipe_through [:browser]

    delete "/authors/log_out", AuthorSessionController, :delete
    get "/authors/confirm", AuthorConfirmationController, :new
    post "/authors/confirm", AuthorConfirmationController, :create
    get "/authors/confirm/:token", AuthorConfirmationController, :confirm
  end
end
