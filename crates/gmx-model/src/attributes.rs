//! Field attributes.
//!
//! Every field carries three attributes that control how widgets treat it.
//! They are set by `ISISAttributes` messages. The names, values and defaults
//! follow `records/Attributes.as` in the legacy client (commit `073e595`).

use std::fmt;
use std::str::FromStr;

/// When a field's value is included in an outbound `ISISDataEdit`.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
pub enum Send {
    /// Only when this field is the one the user changed.
    Changed,
    /// Whenever any field of the record is sent. The legacy default.
    #[default]
    Always,
    /// Never.
    Never,
}

/// Whether the user may edit a field through its widgets.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
pub enum Permissions {
    /// Shown but not editable.
    ReadOnly,
    /// Shown greyed out.
    Disabled,
    /// Editable. The legacy default.
    #[default]
    ReadWrite,
}

/// Progress of the service action a field triggers.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
pub enum ActionState {
    /// The action was requested and has not completed.
    Waiting,
    /// The action failed.
    Failed,
    /// Idle or completed. The legacy default.
    #[default]
    Ok,
    /// The action is running.
    Active,
}

/// The attribute values of one field.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
pub struct Attributes {
    /// When the field is sent in data edits.
    pub send: Send,
    /// Whether the field is editable.
    pub permissions: Permissions,
    /// Progress of the triggered action.
    pub action_state: ActionState,
}

/// A partial attribute change. `None` leaves the current value unchanged.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, Hash)]
pub struct AttributeUpdate {
    /// New `send` value, if any.
    pub send: Option<Send>,
    /// New `permissions` value, if any.
    pub permissions: Option<Permissions>,
    /// New `actionState` value, if any.
    pub action_state: Option<ActionState>,
}

impl AttributeUpdate {
    /// Returns true when the update changes nothing.
    pub fn is_empty(&self) -> bool {
        self.send.is_none() && self.permissions.is_none() && self.action_state.is_none()
    }
}

impl Attributes {
    /// Applies a partial update and reports whether anything changed.
    pub fn apply(&mut self, update: &AttributeUpdate) -> bool {
        let before = *self;
        if let Some(send) = update.send {
            self.send = send;
        }
        if let Some(permissions) = update.permissions {
            self.permissions = permissions;
        }
        if let Some(action_state) = update.action_state {
            self.action_state = action_state;
        }
        *self != before
    }
}

/// An attribute string that is not one of the accepted values.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct InvalidAttribute {
    /// The attribute name, as it appears on the wire.
    pub attribute: &'static str,
    /// The rejected value.
    pub value: String,
    /// The accepted values.
    pub expected: &'static str,
}

impl fmt::Display for InvalidAttribute {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "invalid {}='{}'; expected one of {} (not case sensitive)",
            self.attribute, self.value, self.expected
        )
    }
}

impl std::error::Error for InvalidAttribute {}

impl Send {
    /// The canonical wire spelling.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Changed => "changed",
            Self::Always => "always",
            Self::Never => "never",
        }
    }
}

impl FromStr for Send {
    type Err = InvalidAttribute;

    /// Parses the legacy values case-insensitively.
    ///
    /// `true` and `false` are also accepted as `always` and `never`. The
    /// legacy client never used them, but `docs/protocol_reference.adoc`
    /// once described `send` as a flag, and the Python reference server
    /// wrote booleans.
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_ascii_lowercase().as_str() {
            "changed" => Ok(Self::Changed),
            "always" | "true" => Ok(Self::Always),
            "never" | "false" => Ok(Self::Never),
            _ => Err(InvalidAttribute {
                attribute: "send",
                value: s.to_owned(),
                expected: "'always', 'changed', 'never'",
            }),
        }
    }
}

impl Permissions {
    /// The canonical wire spelling.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::ReadOnly => "readOnly",
            Self::Disabled => "disabled",
            Self::ReadWrite => "readWrite",
        }
    }
}

impl FromStr for Permissions {
    type Err = InvalidAttribute;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_ascii_lowercase().as_str() {
            "readonly" => Ok(Self::ReadOnly),
            "disabled" => Ok(Self::Disabled),
            "readwrite" => Ok(Self::ReadWrite),
            _ => Err(InvalidAttribute {
                attribute: "permissions",
                value: s.to_owned(),
                expected: "'readOnly', 'disabled', 'readWrite'",
            }),
        }
    }
}

impl ActionState {
    /// The canonical wire spelling.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Waiting => "waiting",
            Self::Failed => "failed",
            Self::Ok => "ok",
            Self::Active => "active",
        }
    }
}

impl FromStr for ActionState {
    type Err = InvalidAttribute;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_ascii_lowercase().as_str() {
            "waiting" => Ok(Self::Waiting),
            "failed" => Ok(Self::Failed),
            "ok" => Ok(Self::Ok),
            "active" => Ok(Self::Active),
            _ => Err(InvalidAttribute {
                attribute: "actionState",
                value: s.to_owned(),
                expected: "'waiting', 'failed', 'ok', 'active'",
            }),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_match_legacy() {
        let attrs = Attributes::default();
        assert_eq!(attrs.send, Send::Always);
        assert_eq!(attrs.permissions, Permissions::ReadWrite);
        assert_eq!(attrs.action_state, ActionState::Ok);
    }

    #[test]
    fn parsing_is_case_insensitive_and_round_trips() {
        for send in [Send::Changed, Send::Always, Send::Never] {
            assert_eq!(send.as_str().to_uppercase().parse(), Ok(send));
        }
        for perm in [
            Permissions::ReadOnly,
            Permissions::Disabled,
            Permissions::ReadWrite,
        ] {
            assert_eq!(perm.as_str().to_uppercase().parse(), Ok(perm));
        }
        for state in [
            ActionState::Waiting,
            ActionState::Failed,
            ActionState::Ok,
            ActionState::Active,
        ] {
            assert_eq!(state.as_str().to_uppercase().parse(), Ok(state));
        }
    }

    #[test]
    fn send_accepts_boolean_aliases() {
        assert_eq!("true".parse(), Ok(Send::Always));
        assert_eq!("false".parse(), Ok(Send::Never));
    }

    #[test]
    fn invalid_values_are_rejected() {
        let err = "sometimes".parse::<Send>().unwrap_err();
        assert_eq!(err.attribute, "send");
        assert!(err.to_string().contains("sometimes"));
        assert!("rw".parse::<Permissions>().is_err());
        assert!("done".parse::<ActionState>().is_err());
    }

    #[test]
    fn apply_reports_changes() {
        let mut attrs = Attributes::default();
        assert!(!attrs.apply(&AttributeUpdate::default()));
        let update = AttributeUpdate {
            permissions: Some(Permissions::ReadOnly),
            ..Default::default()
        };
        assert!(attrs.apply(&update));
        assert_eq!(attrs.permissions, Permissions::ReadOnly);
        assert!(!attrs.apply(&update));
    }
}
