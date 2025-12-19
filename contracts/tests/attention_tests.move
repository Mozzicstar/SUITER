#[cfg(test)]
module suiter::attention_tests {
    use suiter::attention;
    use sui::tx_context;

    #[test]
    fun test_start_session() {
        let ctx = &mut tx_context::dummy();
        let reader = @0x1;
        let post_id = sui::object::id_from_address(reader);
        let reader_rep = 100u64;
        
        let session = attention::start_session(reader, post_id, reader_rep, ctx);
        
        let (addr, duration, rep, reward, claimed) = attention::view_session(&session);
        assert!(addr == reader, 1);
        assert!(duration == 0, 2);
        assert!(rep == reader_rep, 3);
        assert!(reward == 0, 4);
        assert!(!claimed, 5);
        
        let _ = session;
    }
}
