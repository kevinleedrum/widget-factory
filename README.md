# The Widget Factory

The Widget Factory is a Rails 7 application for creating and distributing widgets in applications. Initially, this will be implemented in Nucleus but may go beyond if it proves successful.

## Development Setup

See `/docs/apdev.md` for development within Docker.

Alternatively, after forking and cloning the repository. From your terminal:

1. `bundle install`
2. `yarn install`
3. `lefthook install` (Installed by bundler. This will add linting validations pre-push)
4. `rails s -p 30013` (This is the default port expected by Nucleus)

### Requirements

#### Secure Request Salts

You will need to add a `config/secreq.yml` file with proper salt hashes for secure requests to our services. You can grab the contents of this file from Nucleus when needed.

### Vendor API Access Tokens

There is a `config/vendor_api_data.yml` file. You'll need to create a `config/vendor_api_data.yml` file and add proper credentials for the APIs you're wanting to connect to.

There is a global variable set as `VendorApiAccess`.

## Authentication

When embedded within another MoxiWorks application (e.g. Nucleus), the session ID from the host application should be passed to the Widget Factory. For the embeddable component URLs, this session ID is part of the route (see [Viewing Widgets](#viewing-widgets)). For the API endpoints, the session ID should be passed as a `session_id` query parameter.

### JWT Authentication

Alternatively, a JSON Web Token (JWT) can be passed to the Widget Factory in place of a session ID. You will still need a valid user uuid and password.

1. Encode the password using Base64. For example, in your terminal:

```bash
echo -n "password" | openssl base64
```

2. Send a POST request to `/api/jwt` with the following body:

```json
{
  "uuid": "user-uuid-goes-here",
  "password": "encoded-password-goes-here"
}
```

The response body will be in the following format:

```json
{
  "token": "token-will-appear-here",
  "exp": "03-31-2023 17:02"
}
```

3. For any request to the Widget Factory, pass the `token` value as the `Authorization` header. For the `/component/:name/:session_id` routes, be sure to pass a dummy value for `session_id` (e.g. `/component/tips/1234`) so the route is matched correctly.

## Viewing Widgets

Widgets are most often displayed within the [Widget Panel Component](#widget-panel-component-my-widgets--widget-library). However, a widget component also has a standalone route at `/component/:name/:session_id`. This is used in Nucleus for the widget admin form preview. If the component has an "expanded" view (i.e. a modal), the route is `/component/:name/:session_id/expanded`.

For both of these routes, the `name` parameter is the name of the component (e.g. "list_trac"), and the `session_id` is the session ID of the user (see [Authentication](#authentication)). The session ID acts not only as an authentication mechanism but also as a way to get necessary user data for third-party API requests, such as a user's MLS ID.

## Widget Panel Component (My Widgets / Widget Library)

The `widget_panel` component is used to render both the "My Widgets" panel and the "Widget Library" modal within Nucleus. The "My Widgets" panel is viewable at `/component/widget_panel/:session_id?components={components}`, where `{components}` is a comma-separated list of widget component names. For example, to view the `list_trac` and `tips` widgets, the URL would be `/component/widget_panel/1234?components=list_trac,tips`. This parameter is used by Nucleus to list which widgets are available to the user. Keep in mind that the widget panel may still not display a widget if it has not been activated by an administrator, or if the user has opted to remove it from "My Widgets".

The "Widget Library" is the expanded view of this component, so its route is `/component/widget_panel/:session_id/expanded?components={components}`. The `components` parameter is required for both routes.

### Adding, Removing, and Sorting "My Widgets"

A user may remove a widget from "My Widgets" either by clicking "Remove widget" in the widget's context menu, or via the "Widget Library" modal. When a widget is removed by a user, a record is created in the `user_widgets` table (if one does not already exist for that user and widget), and that record's `removed` column is set to TRUE.

The `user_widgets` table is also used to store the user's custom sorting of widgets. If the widgets are reordered in the "My Widgets" panel, records are created or updated with necessary changes to the `row_order` column.

## Creating a New Internally Hosted Widget

### Create a New Widget Component

A new widget component may be created using the Rails generator. The component must be namespaced for the dynamic routing to work. For example, a `todo_list` component would be namespaced as `TodoList::TodoListComponent`. To create such a component, run the following command from the project root:

`bin/rails g component TodoList::TodoList`

This will create the following files:

```
app/components/todo_list/todo_list_component.rb
app/components/todo_list/todo_list_component.html.erb
test/components/todo_list/todo_list_component_test.rb
```

The component will be viewable at the following URL:

`http://localhost:{port}/component/todo_list/{session_id}`

### Leverage the Inline and Expanded Widget Components

#### Inline Widget Component

The `inline_widget` component is not a widget itself but provides common UI and functionality needed to render a widget "inline" (as shown in "My Widgets"). To use this component, your template should resemble the following:

```erb
<%= render(InlineWidgetComponent.new(widget: @widget, preview_mode: @preview_mode, error: @error)) do %>
  <!-- Your widget's inner HTML goes here -->
<% end %>
```

The Inline Widget component provides many JavaScript utility methods under the `window.WidgetFactory` namespace. These can and should be used to log analytic events, expand the widget, etc. See the `app/assets/javascripts/inline_widget_component.js` file.

#### Expanded Widget Component

The `expanded_widget` component provides the functionality needed to render an "expanded" widget (i.e. a modal). To use this component, your template should resemble the following:

```erb
<%= render(ExpandedWidgetComponent.new(widget: @widget)) do %>
  <!-- Your widget's inner HTML goes here -->
<% end %>
```

### Add Custom JavaScript

If the component requires its own JavaScript, create a file in `app/assets/javascripts`. For example, for the `todo_list` component, create `app/assets/javascripts/todo_list_component.js`, and add the following line to `todo_list_component.html.erb`:

```erb
<%= javascript_include_tag "todo_list_component", type: "module" %>
```

### Add Custom CSS

To add custom CSS, the current convention is to add a directory and `style.css` file to `app/assets/stylesheets`. For example, for the `todo_list` component, create `app/assets/stylesheets/todo_list/style.css`, and add the following line to `todo_list_component.html.erb`:

```erb
<%= stylesheet_link_tag "todo_list/style" %>
```

### Create the Widget Record

The new component will need to be associated with a new widget record in the `widgets` table. This record contains the additional metadata needed to render and manage the widget.

Create a new migration to add the widget record. For example, to add a `todo_list` widget, the migration should perform the following:

```ruby
Widget.create({
  component: "todo_list",
  partner: "Example.com Inc",
  name: "TODO List", # Shown in the header of the widget
  description: "Shows your list of tasks to complete", # Shown in the Widget Library
  logo_link_url: "https://example.com/todo-list", # The external URL that opens when clicking the widget's logo
  status: "ready", # or "draft" if the widget will be activated later by an administrator
  activation_date: Time.zone.now # or nil if the widget will be activated later
})
```

### Add a Default Logo

To add a default logo for a new widget, place the file in a subdirectory of `/assets/images` (e.g. `/assets/images/todo_list/logo.png`). Then, update your migration to attach the logo to the widget:

```ruby
Widget.find_by(component: "todo_list").logo.attach(io: File.open(Rails.root.join("app/assets/images/todo_list/logo.png")), filename: "logo.png")
```

## External Widgets

External widgets are hosted by a third party. The `external_widget` component simply renders the `Widget.external_url` in an iframe. It may also render the `external_expanded_url` or `external_preview_url` depending on the scenario.

A widget in the `widgets` table is considered "external" if:

- the `external_url` column is populated, _and_
- the `component` column value begins with `external` (e.g. `external_1`). TODO: Once these are created via the developer portal, we will need to come up with a convention and logic for generating unique component names.

The external URL may make use of the following variables:

- `{FULL_NAME}`: The current user's full name
- `{MLS_NUMBER}`: The current user's MLS number
- `{NRDS_NUMBER}`: The current user's NRDS number

These variables will be replaced with the user's information when the widget is rendered. For example, if the `external_url` is `https://example.com?name={FULL_NAME}`, and the user's full name is "John Doe", the iframe will render `https://example.com?name=John%20Doe`.

## Widget Statuses

There are quite a few possible values for `Widget.status`, and they do not always match the status text that is shown in the Nucleus Admin or Developer Portal. For example, "Draft" in the Developer Portal is not the same as "Draft" in the Nucleus Admin. Refer to the following table.

| Developer Portal | Database Value  | Nucleus Admin      |
| ---------------- | --------------- | ------------------ |
| Draft            | `"unsubmitted"` | _Not shown_        |
| Submitted        | `"submitted"`   | Needs Review       |
| In Review        | `"review"`      | Needs Review       |
| Rejected         | `"rejected"`    | Rejected           |
| Approved         | `"draft"`       | Draft              |
| Approved         | `"ready"`       | Active / Scheduled |
| Approved         | `"deactivated"` | Deactivated        |

## API Endpoints

As [mentioned previously](#authentication), all API requests should provide a `session_id` query parameter for authentication purposes. This parameter is not required for the `/api/jwt` endpoint.

### GET /api/widgets

Returns an array of all widgets.

### GET /api/widgets/:id

Returns a single widget.

Example response:

```json
{
  "id": 4,
  "component": "external_4",
  "partner": "Example.com Inc",
  "name": "TODO List",
  "description": "Shows your list of tasks to complete",
  "logo_link_url": "https://example.com/todo-list",
  "status": "ready",
  "activation_date": "2023-06-01T17:28:52.293Z",
  "updated_by": "John Doe",
  "created_at": "2023-03-24T18:19:00.770Z",
  "updated_at": "2023-06-01T17:28:52.293Z",
  "external_url": "https://example.com/todo-list/list?name={FULL_NAME}",
  "external_preview_url": null,
  "external_expanded_url": "https://example.com/todo-list/full-list?name={FULL_NAME}",
  "submitted_at": "2023-03-24T18:19:00.770Z",
  "submitted_by_uuid": "12345678-1234-1234-1234-123456789012",
  "submission_notes": null,
  "admin_response": null,
  "parent_widget_id": null,
  "remove_logo": null,
  "activated": true,
  "logo_url": "/rails/active_storage/blobs/redirect/.../logo.png",
  "widget_submission_logs": [
    {
      "id": 158,
      "widget_id": 4,
      "status": "submitted",
      "notes": "Submission notes go here.",
      "updated_by": null,
      "logo_link_url": "https://example.com/todo-list",
      "external_url": "https://example.com/todo-list/list?name={FULL_NAME}",
      "external_preview_url": "",
      "external_expanded_url": "https://example.com/todo-list/full-list?name={FULL_NAME}",
      "created_at": "2023-03-24T18:19:00.770Z",
      "updated_at": "2023-03-24T18:19:00.770Z"
    }
  ],
  "revisions": [], // If the widget is in the process of being revised, the revised widget will be the only element in this array
  "parent_widget": null // If the widget is a revision, the parent widget will be returned here
}
```

### POST /api/widgets

Creates a new widget.

Example request body:

```json
{
  "name": "TODO List",
  "partner": "Example.com Inc",
  "description": "Shows your list of tasks to complete",
  "logo_link_url": "https://example.com/todo-list",
  "status": "unsubmitted",
  "external_url": "https://www.example.com",
  "external_preview_url": "https://www.example.com",
  "external_expanded_url": "https://www.example.com",
  "submitted_by_uuid": "12345678-1234-1234-1234-123456789012",
  "updated_by": "John Doe",
  "logo_base64": "iVB...g==" // Base64 encoded logo
}
```

Example response body:

```json
{
  "id": 4,
  "component": "external_4",
  "partner": "Example.com Inc",
  "name": "TODO List",
  "description": "Shows your list of tasks to complete",
  "logo_link_url": "https://example.com/todo-list",
  "status": "unsubmitted",
  "external_url": "https://www.example.com",
  "external_preview_url": "https://www.example.com",
  "external_expanded_url": "https://www.example.com",
  "submitted_by_uuid": "12345678-1234-1234-1234-123456789012",
  "activation_date": null,
  "updated_by": "John Doe",
  "created_at": "2023-10-06T14:23:47.538Z",
  "updated_at": "2023-10-06T14:23:47.538Z",
  "submitted_at": null,
  "submission_notes": null,
  "admin_response": null,
  "parent_widget_id": null,
  "remove_logo": null,
  "activated": false,
  "logo_url": "/rails/active_storage/blobs/redirect/.../logo.png"
}
```

### PATCH/PUT /api/widgets/:id

Updates a widget.

Example request body:

```json
{
  "name": "My New Widget",
  "status": "ready",
  "activation_date": "2023-06-01T17:28:52.293Z", // The date the widget should be activated. Activation also requires that the `status` be set to "ready"
  "description": "My new widget!",
  "updated_by": "John Doe",
  "remove_logo": true, // If true, the widget's logo will be removed
  "logo_base64": "iVB...g=="
}
```

The response will be the updated widget.

### PATCH /api/widgets/:id/revise

Creates a revision for the widget with the specified ID. The revision is a duplicate of the existing widget, but with a different ID, and with the `parent_widget_id` set to the existing widget's ID. If a revision already exists for the widget, the existing revision is returned in order to prevent multiple revisions from being created.

No request body is required.

Example response:

```json
{
  "id": 5,
  "component": "external_5",
  "parent_widget_id": 4, // The ID of the existing widget
  "status": "unsubmitted",
  "partner": "Example.com Inc",
  "name": "TODO List",
  "description": "Shows your list of tasks to complete",
  "logo_link_url": "https://example.com/todo-list",
  "activation_date": null,
  "updated_by": null,
  "created_at": "2023-10-06T14:04:07.976Z",
  "updated_at": "2023-10-06T14:04:07.998Z",
  "external_url": "https://example.com/todo-list/list?name={FULL_NAME}",
  "external_preview_url": null,
  "external_expanded_url": "https://example.com/todo-list/full-list?name={FULL_NAME}",
  "submitted_at": null,
  "submitted_by_uuid": "12345678-1234-1234-1234-123456789012",
  "submission_notes": null,
  "admin_response": null,
  "remove_logo": null,
  "activated": false,
  "logo_url": "/rails/active_storage/blobs/redirect/.../logo.png"
}
```

### PATCH /api/widgets/:id/merge

Merges the specified revision into its parent widget. The revision will be deleted during this process. No request body is required. The response will be the merged widget (the `id` will be the original parent widget's ID).

### DELETE /api/widgets/:id

Deletes the widget with the specified ID. A widget may only be deleted in the following cases:

- Its `status` is either "unsubmitted", "rejected", or "submitted".
- It is an approved revision that has not been merged. In other words, its `status` is "draft" and it has a `parent_widget_id`.

### PATCH /api/user_widgets

Updates the order of the user's My Widgets. The request body should have a property called `widget_ids` which is an ordered array of widget IDs. For example:

```json
{
  "widget_ids": [1, 13, 3]
}
```

### DELETE /api/user_widgets/:id

Removes a widget from the user's My Widgets.

### POST /api/user_widgets/:id/restore

Restores a widget to the user's My Widgets.

### POST /api/jwt

See [JWT Authentication](#jwt-authentication).

### POST /api/events

Logs an event for analtyics purpose. This endpoint is used internally by the Widget Panel component. Ideally, widgets should not make requests to this endpoint directly but rather use the `window.WidgetFactory.logEvent` method or manually use `window.self.postMessage` to send the event to the Widget Panel (see `app/assets/javascripts/inline_widget_component.js`).

Example request body:

```json
{
  "component": "todo_list",
  "event_type": "widget_click_cta",
  "event_data": {} // Optional
}
```
