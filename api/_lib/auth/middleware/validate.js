function validate(body, rules) {
  const errors = [];
  for (const [field, rule] of Object.entries(rules)) {
    const value = body[field];
    if (rule.required && (value === undefined || value === null || value === '')) {
      errors.push(`${field} is required`);
      continue;
    }
    if (value !== undefined && value !== null && value !== '') {
      if (rule.type === 'email' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
        errors.push(`${field} must be a valid email`);
      }
      if (rule.minLength && value.length < rule.minLength) {
        errors.push(`${field} must be at least ${rule.minLength} characters`);
      }
      if (rule.maxLength && value.length > rule.maxLength) {
        errors.push(`${field} must be at most ${rule.maxLength} characters`);
      }
    }
  }
  return errors;
}

function validateGoogleLogin(body) {
  return validate(body, {
    idToken: { required: true, type: 'string' },
  });
}

function validateRefresh(body) {
  return validate(body, {
    refreshToken: { required: true, type: 'string' },
  });
}

module.exports = { validate, validateGoogleLogin, validateRefresh };
