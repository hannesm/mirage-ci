module Git = Current_git
module Github = Current_github

module Website_description = struct
  open Tyxml_html

  let extra_routes = []

  module Output = struct
    type t = unit

    open Tyxml_html

    let render_inline () = txt ""
  end

  module Node = struct
    type t = string

    let render_inline name = txt name
    let map_status _ = Fun.id
  end

  module Stage = struct
    type t = string

    let id name = name
    let render_inline name = txt name
    let render _ = txt ""
  end

  module Pipeline = struct
    type t = Mirage_ci_pipelines.PR.pipeline

    let to_link (t : t) =
      match t with
      | `Local _ -> ""
      | `Github { ref = `PR { id; _ }; owner; name; _ } ->
          Fmt.str "https://github.com/%s/%s/pull/%d" owner name id
      | `Github { ref = `Ref b; owner; name; _ } ->
          Fmt.str "https://github.com/%s/%s/tree/%s" owner name b

    let build_mode_to_string = function
      | `Mirage_3 -> "mirage-3"
      | `Mirage_4 -> "mirage-4"

    let id (t : t) =
      match t with
      | `Local `Mirage_3 -> "local-mirage-3"
      | `Local `Mirage_4 -> "local-mirage-4"
      | `Github { ref = `PR { id; _ }; owner; name; commit; build_mode; _ } ->
          Fmt.str "pr-%d-%s-%s-%s-%s" id
            (build_mode_to_string build_mode)
            owner name commit
      | `Github { ref = `Ref b; owner; name; commit; build_mode; _ } ->
          Fmt.str "branch-%s-%s-%s-%s-%s" b
            (build_mode_to_string build_mode)
            owner name commit

    let render_inline (t : t) =
      match t with
      | `Local b -> txt (Fmt.str "Local build (%s)" (build_mode_to_string b))
      | `Github { ref = `PR { id; _ }; owner; name; commit; _ } ->
          let commit_hash = String.sub commit 0 7 in
          txt (Fmt.str "PR %d on %s/%s @ %s" id owner name commit_hash)
      | `Github { ref = `Ref b; owner; name; commit; _ } ->
          let commit_hash = String.sub commit 0 7 in
          txt (Fmt.str "Branch %s of %s/%s @ %s" b owner name commit_hash)

    let render (t : t) =
      div [ txt "Link to "; a ~a:[ a_href (to_link t) ] [ txt "Github" ] ]
  end

  let render_index () = div [ h1 [ txt "Mirage CI" ] ]
end

include Current_web_pipelines.Web.Make (Website_description)
