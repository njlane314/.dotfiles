fn message() -> &'static str {
    "hello"
}

fn main() {
    println!("{}", message());
}

#[cfg(test)]
mod tests {
    use super::message;

    #[test]
    fn message_is_hello() {
        assert_eq!(message(), "hello");
    }
}
