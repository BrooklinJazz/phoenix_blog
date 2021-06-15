defmodule Blog.Accounts.AuthorToken do
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the email may take over the account.
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @change_email_validity_in_days 7
  @session_validity_in_days 60

  schema "authors_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :author, Blog.Accounts.Author

    timestamps(updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.
  """
  def build_session_token(author) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %Blog.Accounts.AuthorToken{token: token, context: "session", author_id: author.id}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the author found by the token.
  """
  def verify_session_token_query(token) do
    query =
      from token in token_and_context_query(token, "session"),
        join: author in assoc(token, :author),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: author

    {:ok, query}
  end

  @doc """
  Builds a token with a hashed counter part.

  The non-hashed token is sent to the author email while the
  hashed part is stored in the database, to avoid reconstruction.
  The token is valid for a week as long as authors don't change
  their email.
  """
  def build_email_token(author, context) do
    build_hashed_token(author, context, author.email)
  end

  defp build_hashed_token(author, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %Blog.Accounts.AuthorToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       author_id: author.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the author found by the token.
  """
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in token_and_context_query(hashed_token, context),
            join: author in assoc(token, :author),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == author.email,
            select: author

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the author token record.
  """
  def verify_change_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns the given token with the given context.
  """
  def token_and_context_query(token, context) do
    from Blog.Accounts.AuthorToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given author for the given contexts.
  """
  def author_and_contexts_query(author, :all) do
    from t in Blog.Accounts.AuthorToken, where: t.author_id == ^author.id
  end

  def author_and_contexts_query(author, [_ | _] = contexts) do
    from t in Blog.Accounts.AuthorToken, where: t.author_id == ^author.id and t.context in ^contexts
  end
end
